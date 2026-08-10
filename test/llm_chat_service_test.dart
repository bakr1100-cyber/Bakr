import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marocfly_ai/services/llm_chat_service.dart';

void main() {
  group('LlmChatService', () {
    test('isConfigured is false without a proxy URL', () {
      final service = LlmChatService(proxyBaseUrl: '');
      expect(service.isConfigured, isFalse);
    });

    test('isConfigured is true once a proxy URL is set', () {
      final service = LlmChatService(proxyBaseUrl: 'https://worker.example');
      expect(service.isConfigured, isTrue);
    });

    test('returns null immediately when not configured, without any HTTP call', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });
      final service = LlmChatService(proxyBaseUrl: '', client: client);

      final reply = await service.reply(const [LlmMessage(role: 'user', content: 'hi')]);

      expect(reply, isNull);
      expect(called, isFalse);
    });

    test('posts to /ai/chat and returns the trimmed reply text', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://worker.example/ai/chat');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['messages'], [
          {'role': 'system', 'content': 'sys'},
          {'role': 'user', 'content': 'Hallo'},
        ]);
        return http.Response(jsonEncode({'reply': '  Marhba! Wohin geht die Reise?  '}), 200);
      });
      final service = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);

      final reply = await service.reply(const [
        LlmMessage(role: 'system', content: 'sys'),
        LlmMessage(role: 'user', content: 'Hallo'),
      ]);

      expect(reply, 'Marhba! Wohin geht die Reise?');
    });

    test('jsonMode: true adds json_mode to the request body; false omits it', () async {
      late Map<String, dynamic> lastBody;
      final client = MockClient((request) async {
        lastBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'reply': 'ok'}), 200);
      });
      final service = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);

      await service.reply(const [LlmMessage(role: 'user', content: 'hi')], jsonMode: true);
      expect(lastBody['json_mode'], isTrue);

      await service.reply(const [LlmMessage(role: 'user', content: 'hi')]);
      expect(lastBody.containsKey('json_mode'), isFalse);
    });

    test('returns null on a non-200 response', () async {
      final client = MockClient((request) async => http.Response('error', 500));
      final service = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);

      final reply = await service.reply(const [LlmMessage(role: 'user', content: 'Hallo')]);

      expect(reply, isNull);
    });

    test('returns null when the reply text is empty/whitespace', () async {
      final client =
          MockClient((request) async => http.Response(jsonEncode({'reply': '   '}), 200));
      final service = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);

      final reply = await service.reply(const [LlmMessage(role: 'user', content: 'Hallo')]);

      expect(reply, isNull);
    });

    test('returns null instead of throwing when the request errors', () async {
      final client = MockClient((request) async => throw Exception('network down'));
      final service = LlmChatService(proxyBaseUrl: 'https://worker.example', client: client);

      final reply = await service.reply(const [LlmMessage(role: 'user', content: 'Hallo')]);

      expect(reply, isNull);
    });
  });
}
