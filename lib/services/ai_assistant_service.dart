import 'dart:convert';

import '../core/localization/app_localizations.dart';
import '../models/airport.dart';
import '../models/chat_message.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../models/trip_leg.dart';
import 'flight_search_service.dart';
import 'llm_chat_service.dart';
import 'nlu_service.dart';
import 'price_prediction_service.dart';

/// Orchestrates one turn of the conversation: understand the user's
/// message, merge it into the running [TravelIntent], decide whether to
/// ask a clarifying question or run the search - then phrase the actual
/// reply.
///
/// Understanding what the user wants is tried via the LLM first (see
/// [_extractIntentViaLlm]) - a fixed keyword/regex matcher ([NluService])
/// genuinely cannot follow open-ended phrasing, especially in Darija, and
/// was the actual cause of the assistant "reacting wrong to search" and
/// giving generic replies. [NluService] stays as the fallback for when the
/// LLM is unavailable, fails, times out, or returns something unusable -
/// running the search itself stays fully deterministic either way (see
/// [FlightSearchService]), so a booking flow always works once an intent
/// is resolved. The *wording* of the reply is a separate LLM call (see
/// [LlmChatService]), grounded in the concrete facts of this turn so it
/// can't invent prices, cities, or dates. If the LLM is unavailable, fails,
/// or times out at any point, this falls back to the same fixed template
/// replies used before it existed - the app never breaks because a free
/// daily AI quota ran out.
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
    final parsed = await _extractIntentViaLlm(userText, conversationState, language) ??
        _nlu.parse(userText, conversationState: conversationState);
    final merged = conversationState.mergedWith(parsed);

    if (parsed.isLowConfidence && parsed.origin != null && parsed.destination != null) {
      final fallback =
          _confirmRouteFallback(language, parsed.origin!.city, parsed.destination!.city);
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
        fallback: _clarifyingQuestion(missing, language),
      );
      return AssistantTurn(reply: reply, intent: merged);
    }

    final results = await _flights.search(merged, language: language);
    if (results.isEmpty) {
      final reply = await _phrase(
        history: history,
        language: language,
        situation: 'No flights or alternative routes were found for '
            '${merged.origin?.city} -> ${merged.destination?.city} on the '
            'requested date. Tell the user warmly, and suggest trying another '
            'date or destination.',
        fallback: _noFlightsFoundFallback(language),
      );
      return AssistantTurn(reply: reply, intent: merged);
    }

    final best = results.first;
    final prediction = _prices.predict(
      currentPriceEur: best.totalPriceEur,
      departureDate: best.departureTime,
      language: language,
    );

    final buffer = StringBuffer();
    if (results.length > 1) {
      buffer.writeln(_foundCheaperAlternativesFallback(language));
    }
    buffer.writeln(_totalPriceFallback(language, best.explanation, best.totalPriceEur));
    buffer.write(prediction.message);

    final reply = await _phrase(
      history: history,
      language: language,
      situation: _searchResultsSituation(merged, results, prediction.message),
      fallback: buffer.toString(),
    );

    return AssistantTurn(reply: reply, intent: merged, results: results);
  }

  static final List<Airport> _knownAirports = [...europeanAirports, ...moroccanAirports];

  /// Asks the LLM to extract origin/destination/date/passengers/budget from
  /// [userText] as strict JSON, constrained to real airport codes so it
  /// can't invent a city that doesn't exist in the app. Returns `null` (so
  /// the caller falls back to [NluService]) whenever the LLM is not
  /// configured, the call fails/times out, the reply isn't valid JSON, or
  /// nothing at all was extracted from it.
  ///
  /// [conversationState] tells it what's already been established (e.g.
  /// "destination is already Casablanca") - without this, a one-word reply
  /// like a bare city name to "where from?" is genuinely ambiguous even to
  /// an LLM with no other context to go on.
  Future<TravelIntent?> _extractIntentViaLlm(
    String userText,
    TravelIntent conversationState,
    AppLanguage language,
  ) async {
    if (_llm == null || !_llm.isConfigured) return null;

    final today = DateTime.now();
    final airportList = _knownAirports.map((a) => '${a.code}=${a.city}').join(', ');
    final knownSoFar = StringBuffer();
    if (conversationState.origin != null) {
      knownSoFar.write('origin=${conversationState.origin!.code} ');
    }
    if (conversationState.destination != null) {
      knownSoFar.write('destination=${conversationState.destination!.code} ');
    }
    final messages = [
      LlmMessage(
        role: 'system',
        content: 'You extract structured travel-search data from one user message for a '
            'flight-search chatbot. Respond with ONLY a single JSON object and nothing '
            'else - no markdown, no explanation - in exactly this shape:\n'
            '{"origin_code": string|null, "destination_code": string|null, '
            '"date": "YYYY-MM-DD"|null, "passengers": integer|null, '
            '"budget_eur": number|null, "family": true|false|null, '
            '"avoid_layover": true|false|null}\n'
            'Only ever use an airport code from this exact list, never invent one: '
            '$airportList\n'
            "Today's date is ${today.toIso8601String().split('T').first}. Resolve relative "
            'dates ("tomorrow", "next week", "غدا", "الأسبوع الجاي") to an actual date. '
            'Leave a field null if the message does not mention it - do not guess. The '
            'user may write in German, French, English, Modern Standard Arabic, or '
            'Moroccan Darija (Arabic script or Latin transliteration).\n'
            '${knownSoFar.isEmpty ? '' : 'Already established from earlier in this conversation: '
                '$knownSoFar- if this message names exactly one more city with no '
                'explicit "from"/"to" wording, it almost always fills in whichever of '
                'origin/destination is still missing above, not the one already set.\n'}',
      ),
      LlmMessage(role: 'user', content: userText),
    ];

    final raw = await _llm.reply(messages, jsonMode: true);
    if (raw == null) return null;

    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) return null;

    try {
      final json = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      final origin = findAirportByCode(json['origin_code'] as String?);
      final destination = findAirportByCode(json['destination_code'] as String?);
      final dateStr = json['date'] as String?;
      final date = dateStr == null ? null : DateTime.tryParse(dateStr);
      final passengers = (json['passengers'] as num?)?.toInt();
      final budget = (json['budget_eur'] as num?)?.toDouble();
      final family = json['family'] as bool?;
      final avoidLayover = json['avoid_layover'] as bool?;

      final nothingExtracted = origin == null &&
          destination == null &&
          date == null &&
          passengers == null &&
          budget == null &&
          family == null &&
          avoidLayover == null;
      if (nothingExtracted) return null;

      return TravelIntent(
        origin: origin,
        destination: destination,
        departureDate: date,
        passengerCount: passengers,
        maxBudgetEur: budget,
        avoidLongLayover: avoidLayover ?? false,
        travelingWithFamily: family ?? false,
        // A code that made it through is either a real match against
        // _knownAirports or null - never a fuzzy guess - so this path
        // never needs the "did you mean X to Y?" confirmation step.
        isLowConfidence: false,
      );
    } catch (_) {
      return null;
    }
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
      'You are the AI travel assistant inside "Tayarti" (طيارتي), a flight-search '
      'app built for the Moroccan diaspora living in Europe. You are warm, '
      'concise and conversational - like a knowledgeable friend, not a form. '
      'You help people find flights to Morocco, including creative cheaper '
      'alternatives (other airports nearby, layovers, flight+train combos). '
      'Reply ENTIRELY in ${_languageInstruction(language)} - translate every '
      'word, including country names ("Morocco" -> ${_countryNameIn(language)}) '
      'and common nouns; never leave an English word in the reply. City names '
      '(Casablanca, Fès, etc.) may stay as-is since those are proper nouns '
      'used the same way in every language. Keep replies short (1-3 '
      'sentences) unless you are summarizing flight options.\n\n'
      'CRITICAL: only ever state an airline name, flight number, price, '
      'website or booking link that is literally written in the facts below. '
      'If a detail (e.g. the airline, a flight number, or a direct booking '
      'link/URL) is not in the facts, say you do not have that exact detail '
      'rather than inventing one - never invent an airline name, never '
      'invent or guess a website/URL, never make up a flight number. To '
      'book, tell the user to open the flight card shown in the app and tap '
      'the booking button there - that is the only real booking link that '
      'exists; you cannot generate one yourself.';

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
      ..writeln('Legs: ${best.legs.map(_legFact).join(' Then ')}')
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
      final cheapestModes = cheapest.legs.map((l) => l.mode).toSet();
      if (cheapestModes.contains(LegMode.flight) &&
          (cheapestModes.contains(LegMode.train) || cheapestModes.contains(LegMode.bus))) {
        buffer.writeln(
          'That cheapest alternative combines a flight with a separately '
          'booked train/bus leg. If you mention it, add a brief, casual '
          'note that the connection between them is not guaranteed and '
          'the user should check the timing themselves - do not phrase it '
          'as a formal legal disclaimer, the app already shows one; just a '
          'friendly heads-up in passing.',
        );
      }
    }

    buffer.writeln(
      'Phrase your reply as two short, genuinely different opinions on this '
      'route instead of one neutral summary - per explicit request, replies '
      'about search results should never sound like a neutral advice column. '
      'One voice cares mainly about saving money ("Sparfuchs"-type), the '
      'other mainly about comfort/time/convenience. Give each voice a short '
      'label translated into the reply\'s own language (e.g. German: '
      '"Sparfuchs:" / "Komfort:") and 1-2 sentences. Both voices must only '
      'use the facts given above - never invent numbers, airlines, or '
      'details beyond them just to make a voice sound more opinionated.',
    );

    return buffer.toString();
  }

  /// The one true source for airline/flight-number facts handed to the LLM -
  /// without this, the model had nothing concrete to answer "which airline?"
  /// with and started inventing a plausible-sounding one instead (observed
  /// live: it invented "TUI Fly" as the carrier, plus a fake booking URL).
  String _legFact(TripLeg leg) {
    final carrier = leg.carrier;
    final flightNumber = leg.flightNumber;
    final identity = switch ((carrier, flightNumber)) {
      (null, null) => 'carrier unknown',
      (final c?, null) => c,
      (null, final f?) => f,
      (final c?, final f?) => '$c $f',
    };
    return '${leg.mode.name} ${leg.from.city}->${leg.to.city} ($identity).';
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

  String _clarifyingQuestion(String missingField, AppLanguage language) {
    switch (missingField) {
      case 'destination':
        return switch (language) {
          AppLanguage.de => 'Wohin möchtest du reisen? Zum Beispiel nach Casablanca oder Fès?',
          AppLanguage.fr => 'Où veux-tu voyager ? Par exemple à Casablanca ou Fès ?',
          AppLanguage.en => 'Where do you want to travel to? For example Casablanca or Fès?',
          AppLanguage.ar => 'إلى أين تريد السفر؟ على سبيل المثال الدار البيضاء أو فاس؟',
          AppLanguage.ary => 'فين بغيتي تسافر؟ مثلا الدار البيضاء ولا فاس؟',
        };
      case 'origin':
        return switch (language) {
          AppLanguage.de => 'Von wo aus möchtest du losfliegen?',
          AppLanguage.fr => "D'où veux-tu partir ?",
          AppLanguage.en => 'Where do you want to fly from?',
          AppLanguage.ar => 'من أين تريد الإقلاع؟',
          AppLanguage.ary => 'منين بغيتي تطير؟',
        };
      case 'date':
        return switch (language) {
          AppLanguage.de => 'Wann möchtest du reisen?',
          AppLanguage.fr => 'Quand veux-tu voyager ?',
          AppLanguage.en => 'When do you want to travel?',
          AppLanguage.ar => 'متى تريد السفر؟',
          AppLanguage.ary => 'إمتى بغيتي تسافر؟',
        };
      default:
        return switch (language) {
          AppLanguage.de => 'Erzähl mir noch etwas mehr über deine Reise.',
          AppLanguage.fr => 'Raconte-moi un peu plus sur ton voyage.',
          AppLanguage.en => 'Tell me a bit more about your trip.',
          AppLanguage.ar => 'أخبرني بمزيد من التفاصيل عن رحلتك.',
          AppLanguage.ary => 'قوليا شوية كثر على السفرة ديالك.',
        };
    }
  }

  String _confirmRouteFallback(AppLanguage language, String origin, String destination) =>
      switch (language) {
        AppLanguage.de => 'Ich bin mir nicht ganz sicher. Meintest du $origin nach $destination?',
        AppLanguage.fr => 'Je ne suis pas totalement sûr. Tu voulais dire $origin vers $destination ?',
        AppLanguage.en => "I'm not entirely sure. Did you mean $origin to $destination?",
        AppLanguage.ar => 'لست متأكدًا تمامًا. هل تقصد من $origin إلى $destination؟',
        AppLanguage.ary => 'ماشي متأكد بزاف. واش قصدك من $origin ل $destination؟',
      };

  String _noFlightsFoundFallback(AppLanguage language) => switch (language) {
        AppLanguage.de =>
          'Ich habe für diese Route noch keine Verbindung gefunden. Magst du ein anderes Datum '
              'oder Ziel versuchen?',
        AppLanguage.fr =>
          "Je n'ai pas encore trouvé de connexion pour cet itinéraire. Veux-tu essayer une autre "
              'date ou destination ?',
        AppLanguage.en =>
          "I haven't found a connection for this route yet. Want to try another date or "
              'destination?',
        AppLanguage.ar =>
          'لم أجد رحلة لهذا المسار بعد. هل تريد تجربة تاريخ أو وجهة أخرى؟',
        AppLanguage.ary => 'مالقيتش رحلة لهاد المسار حتى دابا. بغيتي تجرب تاريخ ولا وجهة أخرى؟',
      };

  String _foundCheaperAlternativesFallback(AppLanguage language) => switch (language) {
        AppLanguage.de => 'Ich habe günstigere Alternativen gefunden.',
        AppLanguage.fr => "J'ai trouvé des alternatives moins chères.",
        AppLanguage.en => 'I found cheaper alternatives.',
        AppLanguage.ar => 'وجدت بدائل أرخص.',
        AppLanguage.ary => 'لقيت بدائل أرخص.',
      };

  String _totalPriceFallback(AppLanguage language, String explanation, double totalPriceEur) {
    final price = totalPriceEur.toStringAsFixed(0);
    return switch (language) {
      AppLanguage.de => '$explanation Gesamtpreis: $price €.',
      AppLanguage.fr => '$explanation Prix total : $price €.',
      AppLanguage.en => '$explanation Total price: €$price.',
      AppLanguage.ar => '$explanation السعر الإجمالي: $price €.',
      AppLanguage.ary => '$explanation الثمن الكامل: $price €.',
    };
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
