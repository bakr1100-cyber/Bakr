import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import 'flight_search_service.dart';
import 'nlu_service.dart';
import 'price_prediction_service.dart';

/// Orchestrates one turn of the conversation: parse the user's message,
/// merge it into the running [TravelIntent], decide whether to ask a
/// clarifying question or run the search, and phrase a friendly reply.
///
/// This is the seam where a real LLM would take over prompt-construction
/// and response phrasing (see [NluService] docs) - the control flow below
/// (merge -> clarify-or-search -> explain) is what any backing model still
/// needs to implement, mocked or not.
class AiAssistantService {
  AiAssistantService({
    NluService? nluService,
    FlightSearchService? flightSearchService,
    PricePredictionService? pricePredictionService,
  })  : _nlu = nluService ?? NluService(),
        _flights = flightSearchService ?? FlightSearchService(),
        _prices = pricePredictionService ?? PricePredictionService();

  final NluService _nlu;
  final FlightSearchService _flights;
  final PricePredictionService _prices;

  Future<AssistantTurn> handleMessage(
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
