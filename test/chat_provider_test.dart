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

/// Resolves after a short delay instead of instantly, so two overlapping
/// [ChatProvider.send] calls genuinely race rather than happening to
/// resolve in the same synchronous tick.
class _DelayedAssistantService extends AiAssistantService {
  @override
  Future<AssistantTurn> handleMessage(
    String userText,
    TravelIntent conversationState, {
    List<ChatMessage> history = const [],
    AppLanguage language = AppLanguage.de,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return AssistantTurn(reply: 'reply to $userText', intent: conversationState);
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

    // Regression test: the opening greeting used to be hardcoded German
    // text regardless of the selected language.
    test('opening greeting is in the language passed to the constructor', () {
      final chat = ChatProvider(
        assistantService: _ThrowingAssistantService(),
        language: AppLanguage.fr,
      );

      expect(chat.messages.single.text, AppLocalizations(AppLanguage.fr).t('aiChatGreeting'));
    });

    test('setLanguage re-greets in the new language before the conversation starts', () {
      final chat = ChatProvider(
        assistantService: _ThrowingAssistantService(),
        language: AppLanguage.de,
      );

      chat.setLanguage(AppLanguage.ar);

      expect(chat.messages, hasLength(1));
      expect(chat.messages.single.text, AppLocalizations(AppLanguage.ar).t('aiChatGreeting'));
    });

    // Regression test: a message sent (typed or spoken) while a previous
    // reply was still in flight used to be silently dropped by an
    // `_isThinking` guard - observed live as "the voice input doesn't hear
    // me" once replies started taking longer (two sequential LLM calls
    // instead of one). Overlapping sends must now queue instead.
    test('a message sent while a previous reply is still in flight is queued, not dropped',
        () async {
      final chat = ChatProvider(assistantService: _DelayedAssistantService());
      final messageCountBefore = chat.messages.length;

      final first = chat.send('first');
      final second = chat.send('second');
      await Future.wait([first, second]);

      final texts = chat.messages.skip(messageCountBefore).map((m) => m.text).toList();
      expect(texts, ['first', 'reply to first', 'second', 'reply to second']);
      expect(chat.isThinking, isFalse);
    });

    test('setLanguage does not touch the greeting once a real conversation has started', () async {
      final chat = ChatProvider(
        assistantService: _ThrowingAssistantService(),
        language: AppLanguage.de,
      );
      await chat.send('Hallo');
      final greetingBefore = chat.messages.first.text;

      chat.setLanguage(AppLanguage.ar);

      expect(chat.messages.first.text, greetingBefore);
    });
  });
}
