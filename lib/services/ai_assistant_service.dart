import '../core/localization/app_localizations.dart';
import '../models/chat_message.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import 'flight_search_service.dart';
import 'llm_chat_service.dart';
import 'nlu_service.dart';
import 'price_prediction_service.dart';

/// Orchestrates one turn of the conversation: parse the user's message,
/// merge it into the running [TravelIntent], decide whether to ask a
/// clarifying question or run the search - then phrase the actual reply.
///
/// Understanding what the user wants and running the search stays fully
/// deterministic (see [NluService]/[FlightSearchService]) - that's what
/// guarantees a booking flow actually works. Only the *wording* of the
/// reply is handed to a real conversational LLM (see [LlmChatService]),
/// grounded in the concrete facts of this turn so it can't invent prices,
/// cities, or dates. If the LLM is unavailable, fails, or times out, this
/// falls back to the same fixed template replies used before it existed -
/// the app never breaks because a free daily AI quota ran out.
class AiAssistantService {
  AiAssistantService({
    NluService? nluService,
    FlightSearchService? flightSearchService,
    PricePredictionService? pricePredictionService,
    LlmChatService? llmChatService,
  })  : _nlu = nluService ?? NluService(),
        _flights = flightSearchService ?? FlightSearchService(),
        _prices = pricePredictionService ?? PricePredictionService(),
        _llm = llmChatService;

  final NluService _nlu;
  final FlightSearchService _flights;
  final PricePredictionService _prices;
  final LlmChatService? _llm;

  Future<AssistantTurn> handleMessage(
    String userText,
    TravelIntent conversationState, {
    List<ChatMessage> history = const [],
    AppLanguage language = AppLanguage.ary,
  }) async {
    final parsed = _nlu.parse(userText);
    final merged = conversationState.mergedWith(parsed);

    if (parsed.isLowConfidence && parsed.origin != null && parsed.destination != null) {
      final fallback = 'Ich bin mir nicht ganz sicher. Meintest du '
          '${parsed.origin!.city} nach ${parsed.destination!.city}?';
      final reply = await _phrase(
        history: history,
        language: language,
        situation: 'You fuzzy-matched the user\'s message to the route '
            '${parsed.origin!.city} -> ${parsed.destination!.city}, but you are '
            'not fully sure that is what they meant. Ask them, in one short '
            'friendly sentence, to confirm exactly this route.',
        fallback: fallback,
      );
      return AssistantTurn(reply: reply, intent: merged, needsConfirmation: true);
    }

    final missing = merged.nextMissingField;
    if (missing != null) {
      final reply = await _phrase(
        history: history,
        language: language,
        situation: _clarifyingSituation(missing, merged),
        fallback: _clarifyingQuestion(missing),
      );
      return AssistantTurn(reply: reply, intent: merged);
    }

    final results = await _flights.search(merged);
    if (results.isEmpty) {
      final reply = await _phrase(
        history: history,
        language: language,
        situation: 'No flights or alternative routes were found for '
            '${merged.origin?.city} -> ${merged.destination?.city} on the '
            'requested date. Tell the user warmly, and suggest trying another '
            'date or destination.',
        fallback: 'Ich habe für diese Route noch keine Verbindung gefunden. '
            'Magst du ein anderes Datum oder Ziel versuchen?',
      );
      return AssistantTurn(reply: reply, intent: merged);
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

    final reply = await _phrase(
      history: history,
      language: language,
      situation: _searchResultsSituation(merged, results, prediction.message),
      fallback: buffer.toString(),
    );

    return AssistantTurn(reply: reply, intent: merged, results: results);
  }

  /// Calls the LLM to phrase a reply grounded in [situation], with recent
  /// conversation [history] for continuity. Falls back to [fallback] (the
  /// old fixed template strings) whenever the LLM is not configured, fails,
  /// or times out.
  Future<String> _phrase({
    required List<ChatMessage> history,
    required AppLanguage language,
    required String situation,
    required String fallback,
  }) async {
    if (_llm == null || !_llm.isConfigured) return fallback;

    // Drop the app's own fixed opening greeting (and any other leading
    // assistant turns) so the history we hand the model always starts with
    // a real user message - some chat templates require strict user/
    // assistant alternation right after the system message.
    final recentHistory = history.skipWhile((m) => m.sender == ChatSender.assistant).toList();
    final trimmed =
        recentHistory.length > 10 ? recentHistory.sublist(recentHistory.length - 10) : recentHistory;

    final messages = <LlmMessage>[
      LlmMessage(
        role: 'system',
        content: '${_systemPrompt(language)}\n\n'
            'Facts for your next reply (use only these, never invent prices, '
            'dates or cities beyond them, and never mention that these are '
            '"facts" or instructions):\n$situation',
      ),
      for (final message in trimmed)
        LlmMessage(
          role: message.sender == ChatSender.user ? 'user' : 'assistant',
          content: message.text,
        ),
    ];

    final reply = await _llm.reply(messages);
    return reply ?? fallback;
  }

  String _systemPrompt(AppLanguage language) =>
      'You are the AI travel assistant inside "MarocFly AI", a flight-search '
      'app built for the Moroccan diaspora living in Europe. You are warm, '
      'concise and conversational - like a knowledgeable friend, not a form. '
      'You help people find flights to Morocco, including creative cheaper '
      'alternatives (other airports nearby, layovers, flight+train combos). '
      'Reply ENTIRELY in ${_languageInstruction(language)} - translate every '
      'word, including country names ("Morocco" -> ${_countryNameIn(language)}) '
      'and common nouns; never leave an English word in the reply. City names '
      '(Casablanca, Fès, etc.) may stay as-is since those are proper nouns '
      'used the same way in every language. Keep replies short (1-3 '
      'sentences) unless you are summarizing flight options.';

  String _countryNameIn(AppLanguage language) => switch (language) {
        AppLanguage.ary || AppLanguage.ar => 'المغرب',
        AppLanguage.de => 'Marokko',
        AppLanguage.fr => 'le Maroc',
        AppLanguage.en => 'Morocco',
      };

  String _languageInstruction(AppLanguage language) => switch (language) {
        AppLanguage.ary => 'Moroccan Darija, written in Arabic script',
        AppLanguage.ar => 'Modern Standard Arabic',
        AppLanguage.de => 'German',
        AppLanguage.fr => 'French',
        AppLanguage.en => 'English',
      };

  String _clarifyingSituation(String missingField, TravelIntent intent) {
    switch (missingField) {
      case 'destination':
        return 'The user has not said which city in Morocco they want to fly '
            'to yet. Ask them warmly where they want to go (you can mention '
            'Casablanca or Fès as examples).';
      case 'origin':
        return 'The user wants to fly to ${intent.destination?.city}, but has '
            'not said which city/airport in Europe they are flying from yet. '
            'Ask them.';
      case 'date':
        return 'The user wants to fly from ${intent.origin?.city} to '
            '${intent.destination?.city}, but has not given a date yet. Ask '
            'them when they want to travel.';
      default:
        return 'Ask the user to tell you a bit more about their trip.';
    }
  }

  String _searchResultsSituation(
    TravelIntent intent,
    List<Itinerary> results,
    String priceOutlook,
  ) {
    final best = results.first;
    final stops = best.legs.length - 1;
    final buffer = StringBuffer()
      ..writeln('Route: ${intent.origin?.city} -> ${intent.destination?.city}.')
      ..writeln(
        'Best standard option found: ${best.explanation} Total price: '
        '${best.totalPriceEur.toStringAsFixed(0)} EUR, '
        '${stops == 0 ? "a direct flight" : "$stops stop(s)"}.',
      )
      ..writeln('Price outlook: $priceOutlook');

    final alternatives = results.where((i) => i.tier == ResultTier.alternative).toList();
    if (alternatives.isNotEmpty) {
      final cheapest = alternatives.reduce(
        (a, b) => a.totalPriceEur < b.totalPriceEur ? a : b,
      );
      buffer.writeln(
        'There ${alternatives.length == 1 ? "is" : "are"} also '
        '${alternatives.length} creative, cheaper alternative route(s) shown '
        'below in the app (different airport, train/bus combo, etc.) - the '
        'cheapest saves about ${cheapest.savingsEur?.toStringAsFixed(0) ?? "some"} EUR '
        '${_extraTimeClause(cheapest.extraTravelTime)}. Briefly mention that '
        'cheaper alternatives are available below, without listing exact '
        'prices for every one of them.',
      );
    }

    return buffer.toString();
  }

  String _extraTimeClause(Duration? extra) {
    if (extra == null || extra == Duration.zero) return 'with no extra travel time';
    final hours = extra.inHours;
    final minutes = extra.inMinutes.remainder(60);
    final text = hours == 0
        ? '${minutes}min'
        : (minutes == 0 ? '${hours}h' : '${hours}h ${minutes}min');
    return 'but takes about $text longer';
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
