import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/travel_intent.dart';
import 'package:marocfly_ai/services/ai_assistant_service.dart';
import 'package:marocfly_ai/services/flight_price_source.dart';
import 'package:marocfly_ai/services/flight_search_service.dart';
import 'package:marocfly_ai/services/llm_client.dart';

/// A controllable [LlmClient] for tests: returns canned text for the Nth
/// call (intent extraction is always the first call in a turn; phrasing,
/// if needed, is the second), or throws if configured to.
class FakeLlmClient implements LlmClient {
  FakeLlmClient(this.responses, {this.throwOnCall});

  final List<String> responses;
  final int? throwOnCall;
  int callCount = 0;

  @override
  Future<String> complete({
    required String systemPrompt,
    required List<LlmMessage> history,
  }) async {
    callCount++;
    if (throwOnCall == callCount) {
      throw LlmClientException('simulated failure');
    }
    return responses[callCount - 1];
  }
}

class FakeFlightPriceSource implements FlightPriceSource {
  @override
  Future<FlightQuote?> quoteDirect({
    required Airport origin,
    required Airport destination,
    required DateTime date,
  }) async {
    return FlightQuote(
      priceEur: 210,
      departure: date,
      arrival: date.add(const Duration(hours: 4)),
      carrier: 'TestAir',
    );
  }
}

void main() {
  late FlightSearchService flights;

  setUp(() {
    flights = FlightSearchService(priceSource: FakeFlightPriceSource());
  });

  test('LLM path asks a clarifying question when a field is missing', () async {
    final llm = FakeLlmClient([
      jsonEncode({
        'origin_iata': 'DUS',
        'destination_iata': null,
        'departure_date': null,
        'passenger_count': null,
        'max_budget_eur': null,
        'avoid_long_layover': false,
        'traveling_with_family': false,
        'detected_language': 'de',
        'needs_confirmation': false,
        'reply': 'Wohin möchtest du reisen?',
      }),
    ]);
    final service = AiAssistantService(flightSearchService: flights, llmClient: llm);

    final turn = await service.handleMessage('Ich möchte von Düsseldorf verreisen.', const TravelIntent());

    expect(turn.reply, 'Wohin möchtest du reisen?');
    expect(turn.intent.origin?.code, 'DUS');
    expect(turn.needsConfirmation, isFalse);
    expect(llm.callCount, 1);
  });

  test('LLM path runs a real search and phrases the grounded result', () async {
    final llm = FakeLlmClient([
      jsonEncode({
        'origin_iata': 'DUS',
        'destination_iata': 'FEZ',
        'departure_date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'passenger_count': 1,
        'max_budget_eur': null,
        'avoid_long_layover': false,
        'traveling_with_family': false,
        'detected_language': 'en',
        'needs_confirmation': false,
        'reply': 'Checking that for you...',
      }),
      'Here is a great flight from Düsseldorf to Fès for 210 €.',
    ]);
    final service = AiAssistantService(flightSearchService: flights, llmClient: llm);

    final turn = await service.handleMessage(
      'I want to fly from Düsseldorf to Fès next week.',
      const TravelIntent(),
    );

    expect(turn.results, isNotNull);
    expect(turn.results, isNotEmpty);
    expect(turn.reply, 'Here is a great flight from Düsseldorf to Fès for 210 €.');
    expect(llm.callCount, 2);
  });

  test('LLM path surfaces needs_confirmation from the model', () async {
    final llm = FakeLlmClient([
      jsonEncode({
        'origin_iata': 'DUS',
        'destination_iata': 'FEZ',
        'departure_date': null,
        'passenger_count': null,
        'max_budget_eur': null,
        'avoid_long_layover': false,
        'traveling_with_family': false,
        'detected_language': 'de',
        'needs_confirmation': true,
        'reply': 'Meintest du Düsseldorf nach Fès?',
      }),
    ]);
    final service = AiAssistantService(flightSearchService: flights, llmClient: llm);

    final turn = await service.handleMessage('von dusseldorf nach fes', const TravelIntent());

    expect(turn.needsConfirmation, isTrue);
    expect(turn.reply, 'Meintest du Düsseldorf nach Fès?');
  });

  test('falls back to the rule-based assistant when the LLM call fails', () async {
    final llm = FakeLlmClient([], throwOnCall: 1);
    final service = AiAssistantService(flightSearchService: flights, llmClient: llm);

    final turn = await service.handleMessage(
      'Ich möchte von Düsseldorf nach Fès fliegen.',
      const TravelIntent(),
    );

    // The rule-based NluService should have parsed this directly, proving
    // the LLM failure degraded gracefully instead of throwing.
    expect(turn.intent.origin?.code, 'DUS');
    expect(turn.intent.destination?.code, 'FEZ');
  });

  test('falls back to the rule-based assistant on malformed JSON from the model', () async {
    final llm = FakeLlmClient(['not valid json at all']);
    final service = AiAssistantService(flightSearchService: flights, llmClient: llm);

    final turn = await service.handleMessage(
      'Ich möchte von Düsseldorf nach Fès fliegen.',
      const TravelIntent(),
    );

    expect(turn.intent.origin?.code, 'DUS');
    expect(turn.intent.destination?.code, 'FEZ');
  });

  test('with no LlmClient configured, behaves exactly like the rule-based assistant', () async {
    final service = AiAssistantService(flightSearchService: flights);

    final turn = await service.handleMessage('Wohin möchtest du reisen?', const TravelIntent());

    expect(turn.reply, isNotEmpty);
  });
}
