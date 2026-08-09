import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/chat_message.dart';
import 'package:marocfly_ai/models/travel_intent.dart';
import 'package:marocfly_ai/services/ai_assistant_service.dart';
import 'package:marocfly_ai/services/llm_chat_service.dart';

void main() {
  const dus = Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland');
  const fez = Airport(code: 'FEZ', city: 'Fès', country: 'Marokko');
  final departureDate = DateTime.now().add(const Duration(days: 14));

  group('without an LLM configured', () {
    test('falls back to the fixed clarifying-question template', () async {
      final service = AiAssistantService();
      final turn = await service.handleMessage(
        'Ich will verreisen',
        const TravelIntent(),
        language: AppLanguage.de,
      );
      expect(turn.reply, 'Wohin möchtest du reisen? Zum Beispiel nach Casablanca oder Fès?');
    });

    test('falls back to the fixed search-result template', () async {
      final service = AiAssistantService();
      final intent = TravelIntent(origin: dus, destination: fez, departureDate: departureDate);

      final turn =
          await service.handleMessage('Nochmal bitte', intent, language: AppLanguage.de);

      expect(turn.results, isNotNull);
      expect(turn.results, isNotEmpty);
      expect(turn.reply, contains('Gesamtpreis:'));
    });

    // Regression test: the fixed (non-LLM) fallback templates used to be
    // hardcoded German text regardless of [language] - confirmed live via a
    // screenshot where a French-language chat still fell back to German.
    test('phrases the fixed clarifying-question template in the requested language', () async {
      final service = AiAssistantService();
      final turn = await service.handleMessage(
        'Je veux voyager',
        const TravelIntent(),
        language: AppLanguage.fr,
      );
      expect(turn.reply, contains('voyager'));
      expect(turn.reply, isNot(contains('reisen')));
    });
  });

  group('with an LLM configured', () {
    test('uses the LLM-phrased reply instead of the template', () async {
      final client = MockClient(
        (request) async =>
            http.Response(jsonEncode({'reply': 'Klar, wohin soll die Reise gehen?'}), 200),
      );
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      final turn = await service.handleMessage(
        'Ich will verreisen',
        const TravelIntent(),
        language: AppLanguage.de,
      );

      expect(turn.reply, 'Klar, wohin soll die Reise gehen?');
    });

    test('falls back to the template when the LLM call fails', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      final turn = await service.handleMessage(
        'Ich will verreisen',
        const TravelIntent(),
        language: AppLanguage.de,
      );

      expect(turn.reply, 'Wohin möchtest du reisen? Zum Beispiel nach Casablanca oder Fès?');
    });

    test('grounds the LLM in the current facts and drops the opening greeting from history', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'reply': 'ok'}), 200);
      });
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      final history = [
        ChatMessage(
          id: '1',
          sender: ChatSender.assistant,
          text: 'Marhba! Wohin möchtest du reisen?',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          sender: ChatSender.user,
          text: 'Ich will nach Fès',
          timestamp: DateTime.now(),
        ),
      ];

      await service.handleMessage(
        'Ich will nach Fès',
        const TravelIntent(),
        history: history,
        language: AppLanguage.fr,
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      final messages = (body['messages'] as List).cast<Map<String, dynamic>>();

      expect(messages.first['role'], 'system');
      expect(messages.first['content'], contains('French'));
      expect(
        messages.where((m) => m['role'] == 'assistant' && m['content'] == 'Marhba! Wohin möchtest du reisen?'),
        isEmpty,
        reason: 'the fixed opening greeting should not be sent to the LLM',
      );
      expect(
        messages.any((m) => m['role'] == 'user' && m['content'] == 'Ich will nach Fès'),
        isTrue,
      );
    });
  });

  group('LLM-based intent extraction', () {
    // Dispatches by system-prompt content, since one handleMessage() turn
    // can make two different LLM calls (extract the intent, then phrase
    // the reply) - a single fixed response wouldn't let a test control them
    // independently.
    http.Client dispatchingClient({required String extractionReply, String phrasingReply = 'ok'}) {
      return MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final systemContent = (body['messages'] as List).first['content'] as String;
        final isExtractionCall = systemContent.contains('extract structured travel-search data');
        return http.Response(
          jsonEncode({'reply': isExtractionCall ? extractionReply : phrasingReply}),
          200,
        );
      });
    }

    test('LLM-extracted intent takes priority over what the regex parser would have found',
        () async {
      final client = dispatchingClient(
        extractionReply: jsonEncode({
          'origin_code': 'DUS',
          'destination_code': 'FEZ',
          'date': departureDate.toIso8601String().split('T').first,
          'passengers': null,
          'budget_eur': null,
          'family': null,
          'avoid_layover': null,
        }),
      );
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      // The regex parser would resolve this to destination=Casablanca,
      // origin=null - the assertions below only pass if the final route
      // came from the LLM extraction instead.
      final turn = await service.handleMessage(
        'Ich will nach Casablanca',
        const TravelIntent(),
        language: AppLanguage.de,
      );

      expect(turn.intent.origin?.code, 'DUS');
      expect(turn.intent.destination?.code, 'FEZ');
      expect(turn.needsConfirmation, isFalse);
    });

    test('falls back to the regex parser when the extraction reply has no JSON in it', () async {
      final client = dispatchingClient(extractionReply: 'sure, let me help with that!');
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      final turn = await service.handleMessage(
        'Ich will nach Casablanca',
        const TravelIntent(),
        language: AppLanguage.de,
      );

      expect(turn.intent.destination?.code, 'CMN');
    });

    test('falls back to the regex parser when the extracted JSON is malformed', () async {
      final client = dispatchingClient(extractionReply: '{origin_code: DUS, not valid json}');
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      final turn = await service.handleMessage(
        'Ich will nach Casablanca',
        const TravelIntent(),
        language: AppLanguage.de,
      );

      expect(turn.intent.destination?.code, 'CMN');
    });

    test('falls back to the regex parser when the LLM extracts nothing useful', () async {
      final client = dispatchingClient(
        extractionReply: jsonEncode({
          'origin_code': null,
          'destination_code': null,
          'date': null,
          'passengers': null,
          'budget_eur': null,
          'family': null,
          'avoid_layover': null,
        }),
      );
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      final turn = await service.handleMessage(
        'Ich will nach Casablanca',
        const TravelIntent(),
        language: AppLanguage.de,
      );

      expect(turn.intent.destination?.code, 'CMN');
    });

    test('an unknown airport code from the LLM is ignored rather than crashing', () async {
      final client = dispatchingClient(
        extractionReply: jsonEncode({
          'origin_code': 'XXX',
          'destination_code': 'FEZ',
          'date': departureDate.toIso8601String().split('T').first,
          'passengers': null,
          'budget_eur': null,
          'family': null,
          'avoid_layover': null,
        }),
      );
      final llm = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);
      final service = AiAssistantService(llmChatService: llm);

      final turn = await service.handleMessage(
        'Ich will nach Fès',
        const TravelIntent(),
        language: AppLanguage.de,
      );

      expect(turn.intent.origin, isNull);
      expect(turn.intent.destination?.code, 'FEZ');
    });
  });
}
