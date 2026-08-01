import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/models/chat_message.dart';
import 'package:marocfly_ai/models/travel_intent.dart';
import 'package:marocfly_ai/providers/chat_provider.dart';
import 'package:marocfly_ai/services/ai_assistant_service.dart';

/// Always throws, regardless of input - simulates any failure inside
/// handleMessage() (a bad NLU match, a network error not otherwise caught,
/// anything) to verify [ChatProvider] never leaves the conversation stuck.
class _ThrowingAssistantService extends AiAssistantService {
  @override
  Future<AssistantTurn> handleMessage(
    String userText,
    TravelIntent conversationState, {
    List<ChatMessage> history = const [],
    AppLanguage language = AppLanguage.de,
  }) {
    throw Exception('boom');
  }
}

void main() {
  group('ChatProvider', () {
    // Regression test: previously, any exception inside handleMessage()
    // left `_isThinking` stuck at true forever with no reply ever added -
    // the chat just hung silently with no visible error and no way to
    // recover short of restarting the app.
    test('never hangs silently if the assistant throws - always resolves with a fallback reply',
        () async {
      final chat = ChatProvider(assistantService: _ThrowingAssistantService());
      final messageCountBefore = chat.messages.length;

      await chat.send('Hallo');

      expect(chat.isThinking, isFalse);
      expect(chat.messages.length, messageCountBefore + 2); // user turn + fallback reply
      expect(chat.messages.last.sender, ChatSender.assistant);
      expect(chat.messages.last.text, isNotEmpty);
    });

    test('does nothing for empty/whitespace-only input', () async {
      final chat = ChatProvider(assistantService: _ThrowingAssistantService());
      final messageCountBefore = chat.messages.length;

      await chat.send('   ');

      expect(chat.messages.length, messageCountBefore);
      expect(chat.isThinking, isFalse);
    });
  });
}
