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
}
