import 'dart:convert';

import '../models/airport.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import 'flight_search_service.dart';
import 'llm_client.dart';
import 'nlu_service.dart';
import 'price_prediction_service.dart';

/// Orchestrates one turn of the conversation: parse the user's message,
/// merge it into the running [TravelIntent], decide whether to ask a
/// clarifying question or run the search, and phrase a friendly reply.
///
/// Two ways to run this:
/// - No [LlmClient] configured (the default): a deterministic, offline,
///   rule-based path (`NluService` for parsing, fixed German template
///   strings for replies) - this is what ships with no setup and what
///   `test/` exercises.
/// - An [LlmClient] configured (see `ClaudeLlmClient`/`app.dart`): a real
///   hosted LLM understands the message, merges it into the intent, asks
///   clarifying questions, and phrases the final recommendation in the
///   user's own language. The LLM is only ever used for *language*
///   (parsing free text, phrasing replies) - flight/train prices and
///   schedules still come from [FlightSearchService] exactly as before, so
///   the model can't hallucinate a fare. Any LLM failure (network error,
///   bad key, malformed response) falls back to the rule-based path
///   automatically, same fail-safe contract as `DuffelFlightPriceSource`.
class AiAssistantService {
  AiAssistantService({
    NluService? nluService,
    FlightSearchService? flightSearchService,
    PricePredictionService? pricePredictionService,
    LlmClient? llmClient,
  })  : _nlu = nluService ?? NluService(),
        _flights = flightSearchService ?? FlightSearchService(),
        _prices = pricePredictionService ?? PricePredictionService(),
        _llm = llmClient;

  final NluService _nlu;
  final FlightSearchService _flights;
  final PricePredictionService _prices;
  final LlmClient? _llm;

  Future<AssistantTurn> handleMessage(
    String userText,
    TravelIntent conversationState,
  ) async {
    final llm = _llm;
    if (llm != null) {
      try {
        return await _handleMessageWithLlm(userText, conversationState, llm);
      } catch (_) {
        // Degrade to the rule-based assistant rather than let a network
        // error, rate limit or malformed model response reach the UI.
      }
    }
    return _handleMessageRuleBased(userText, conversationState);
  }

  // --- Rule-based path (default, fully offline) --------------------------

  Future<AssistantTurn> _handleMessageRuleBased(
    String userText,
    TravelIntent conversationState,
  ) async {
    final parsed = _nlu.parse(userText);
    final merged = conversationState.mergedWith(parsed);

    if (parsed.isLowConfidence && parsed.origin != null && parsed.destination != null) {
      return AssistantTurn(
        reply: 'Ich bin mir nicht ganz sicher. Meintest du '
            '${parsed.origin!.city} nach ${parsed.destination!.city}?',
        intent: merged,
        needsConfirmation: true,
      );
    }

    final missing = merged.nextMissingField;
    if (missing != null) {
      return AssistantTurn(
        reply: _clarifyingQuestion(missing),
        intent: merged,
      );
    }

    final results = await _flights.search(merged);
    if (results.isEmpty) {
      return AssistantTurn(
        reply: 'Ich habe für diese Route noch keine Verbindung gefunden. '
            'Magst du ein anderes Datum oder Ziel versuchen?',
        intent: merged,
      );
    }

    final best = results.first;
    final prediction = _prices.predict(
      currentPriceEur: best.totalPriceEur,
      departureDate: best.departureTime,
    );

    final buffer = StringBuffer();
    if (results.length > 1) {
      buffer.writeln('Ich habe günstigere Alternativen gefunden.');
    }
    buffer.writeln(
      '${best.explanation} Gesamtpreis: ${best.totalPriceEur.toStringAsFixed(0)} €.',
    );
    buffer.write(prediction.message);

    return AssistantTurn(
      reply: buffer.toString(),
      intent: merged,
      results: results,
    );
  }

  String _clarifyingQuestion(String missingField) {
    switch (missingField) {
      case 'destination':
        return 'Wohin möchtest du reisen? Zum Beispiel nach Casablanca oder Fès?';
      case 'origin':
        return 'Von wo aus möchtest du losfliegen?';
      case 'date':
        return 'Wann möchtest du reisen?';
      default:
        return 'Erzähl mir noch etwas mehr über deine Reise.';
    }
  }

  // --- LLM-backed path -----------------------------------------------------

  Future<AssistantTurn> _handleMessageWithLlm(
    String userText,
    TravelIntent conversationState,
    LlmClient llm,
  ) async {
    final extracted = await _extractIntent(userText, conversationState, llm);
    final merged = conversationState.mergedWith(extracted.intent);

    if (extracted.needsConfirmation) {
      return AssistantTurn(
        reply: extracted.reply,
        intent: merged,
        needsConfirmation: true,
      );
    }

    final missing = merged.nextMissingField;
    if (missing != null) {
      return AssistantTurn(reply: extracted.reply, intent: merged);
    }

    final results = await _flights.search(merged);
    if (results.isEmpty) {
      final reply = await _phraseNoResults(merged, llm);
      return AssistantTurn(reply: reply, intent: merged);
    }

    final reply = await _phraseResults(merged, results, llm);
    return AssistantTurn(reply: reply, intent: merged, results: results);
  }

  Future<_ExtractedIntent> _extractIntent(
    String userText,
    TravelIntent conversationState,
    LlmClient llm,
  ) async {
    final raw = await llm.complete(
      systemPrompt: _intentSystemPrompt,
      history: [
        LlmMessage(
          role: 'user',
          content: jsonEncode({
            'known_so_far': _intentToJson(conversationState),
            'user_message': userText,
          }),
        ),
      ],
    );

    final json = _decodeJsonObject(raw);
    final origin = findAirportByCode(json['origin_iata'] as String?);
    final destination = findAirportByCode(json['destination_iata'] as String?);
    final dateStr = json['departure_date'] as String?;
    final date = dateStr == null ? null : DateTime.tryParse(dateStr);
    final needsConfirmation = json['needs_confirmation'] == true;

    final intent = TravelIntent(
      origin: origin,
      destination: destination,
      departureDate: date,
      passengerCount: (json['passenger_count'] as num?)?.toInt(),
      maxBudgetEur: (json['max_budget_eur'] as num?)?.toDouble(),
      avoidLongLayover: json['avoid_long_layover'] == true,
      travelingWithFamily: json['traveling_with_family'] == true,
      detectedLanguage: json['detected_language'] as String?,
      isLowConfidence: needsConfirmation,
    );

    final reply = (json['reply'] as String?)?.trim();
    if (reply == null || reply.isEmpty) {
      throw LlmClientException('Claude returned an empty reply field');
    }

    return _ExtractedIntent(intent: intent, reply: reply, needsConfirmation: needsConfirmation);
  }

  Future<String> _phraseResults(
    TravelIntent intent,
    List<Itinerary> results,
    LlmClient llm,
  ) async {
    final best = results.first;
    final prediction = _prices.predict(
      currentPriceEur: best.totalPriceEur,
      departureDate: best.departureTime,
    );

    final raw = await llm.complete(
      systemPrompt: _phrasingSystemPrompt,
      history: [
        LlmMessage(
          role: 'user',
          content: jsonEncode({
            'detected_language': intent.detectedLanguage,
            'has_cheaper_alternatives': results.length > 1,
            'best_option_explanation': best.explanation,
            'total_price_eur': best.totalPriceEur,
            'price_trend': prediction.trend.name,
            'price_trend_confidence': prediction.confidence,
          }),
        ),
      ],
    );
    return raw.trim();
  }

  Future<String> _phraseNoResults(TravelIntent intent, LlmClient llm) async {
    final raw = await llm.complete(
      systemPrompt: _phrasingSystemPrompt,
      history: [
        LlmMessage(
          role: 'user',
          content: jsonEncode({
            'detected_language': intent.detectedLanguage,
            'no_results': true,
          }),
        ),
      ],
    );
    return raw.trim();
  }

  Map<String, dynamic> _intentToJson(TravelIntent intent) => {
        'origin_iata': intent.origin?.code,
        'destination_iata': intent.destination?.code,
        'departure_date': intent.departureDate?.toIso8601String(),
        'passenger_count': intent.passengerCount,
        'max_budget_eur': intent.maxBudgetEur,
        'avoid_long_layover': intent.avoidLongLayover,
        'traveling_with_family': intent.travelingWithFamily,
        'detected_language': intent.detectedLanguage,
      };

  Map<String, dynamic> _decodeJsonObject(String raw) {
    // Models occasionally wrap JSON in a ```json ... ``` fence despite
    // instructions not to - strip it defensively rather than fail the turn.
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.substring(text.indexOf('\n') + 1);
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
    }
    try {
      final decoded = jsonDecode(text.trim());
      if (decoded is Map<String, dynamic>) return decoded;
      throw LlmClientException('Expected a JSON object, got: $raw');
    } on FormatException {
      throw LlmClientException('Could not parse JSON from model output: $raw');
    }
  }

  static final _knownAirports = [...europeanAirports, ...moroccanAirports]
      .map((a) => '${a.code}: ${a.city}, ${a.country}')
      .join('\n');

  static final String _intentSystemPrompt = '''
You are the natural-language understanding layer for MarocFly AI, a travel
advisor helping the Moroccan diaspora in Europe find flights/trains/buses
home. You are given the trip details already known so far (`known_so_far`)
and the user's newest free-text or voice-transcribed message
(`user_message`), which may be written in Modern Standard Arabic, Moroccan
Darija (Arabic script or Arabizi/Latin transliteration), German, French or
English.

Known airports/stations you can map city names to (IATA-style code: city,
country):
$_knownAirports

Extract or update the trip details and respond with ONLY a single JSON
object (no markdown fences, no commentary) with exactly these keys:
- origin_iata: one of the codes above the user is departing from, or null
- destination_iata: one of the codes above the user is travelling to, or null
- departure_date: an ISO-8601 date (YYYY-MM-DD) if a date/relative date
  ("next week", "tomorrow") was mentioned, resolved against today's date,
  or null
- passenger_count: integer number of travellers if mentioned or implied
  (e.g. "with my family" implies more than 1), or null
- max_budget_eur: number if a budget in euros was mentioned, or null
- avoid_long_layover: true if the user asked to avoid long layovers/stopovers
- traveling_with_family: true if the user mentioned travelling with family
- detected_language: a short code for the language of user_message - one of
  "de", "fr", "en", "ar" (Modern Standard Arabic), "ary" (Darija, Arabic
  script), "ary-latin" (Darija, Latin/Arabizi script)
- needs_confirmation: true ONLY if you matched a city name you are not
  confident about and should ask the user to confirm before proceeding
- reply: your natural-language reply to the user, written in the SAME
  language as user_message (matching detected_language), never in a
  different language than the user wrote in. If origin, destination or
  date are still missing after merging with known_so_far, ask exactly one
  short, friendly clarifying question for the single most important
  missing field (destination first, then origin, then date). If
  needs_confirmation is true, ask the user to confirm the city you matched
  instead. If everything needed is already known, write a short
  acknowledgement (e.g. "Let me check that for you...") - do not invent
  prices or results here, a follow-up message with the real results comes
  from elsewhere.

Merge rules: any field present in known_so_far and NOT contradicted by
user_message should be carried over unchanged into your response (do not
null out something already known just because this message doesn't repeat
it).
''';

  static const String _phrasingSystemPrompt = '''
You are the reply-phrasing layer for MarocFly AI, a travel advisor for the
Moroccan diaspora in Europe. You are given real, already-computed facts
about a flight/train search (never invent or alter any number in them) as
a JSON object, and must write a short, warm, natural-language reply in the
language given by `detected_language` (default to English if absent or
unrecognized).

If `no_results` is true, apologize briefly and suggest trying a different
date or destination - there are no other facts to report.

Otherwise you are given `best_option_explanation` (why this route/option
was picked), `total_price_eur`, `has_cheaper_alternatives` (mention that
cheaper alternatives were found if true), and a price trend
(`price_trend`: one of "likelyToDrop", "likelyToRise", "stable", with
`price_trend_confidence` from 0 to 1) - translate the trend into a natural
booking recommendation (e.g. book now vs. it's fine to wait) in the
target language.

Respond with ONLY the reply text - no JSON, no markdown, no explanation of
your reasoning.
''';
}

class _ExtractedIntent {
  const _ExtractedIntent({
    required this.intent,
    required this.reply,
    required this.needsConfirmation,
  });

  final TravelIntent intent;
  final String reply;
  final bool needsConfirmation;
}

class AssistantTurn {
  const AssistantTurn({
    required this.reply,
    required this.intent,
    this.results,
    this.needsConfirmation = false,
  });

  final String reply;
  final TravelIntent intent;
  final List<Itinerary>? results;
  final bool needsConfirmation;
}
