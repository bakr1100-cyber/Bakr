import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/providers.dart';

class AiAssistantController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [
        ChatMessage(
          role: ChatRole.assistant,
          text: 'Salam! Wohin möchtest du reisen? Du kannst auf Darija, '
              'Arabisch, Deutsch, Französisch oder Englisch schreiben.',
          timestamp: DateTime.now(),
        ),
      ];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = ChatMessage(
      role: ChatRole.user,
      text: text,
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];

    final reply = await ref.read(llmClientProvider).sendMessage(state, text);
    state = [
      ...state,
      ChatMessage(
        role: ChatRole.assistant,
        text: reply,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final aiAssistantControllerProvider =
    NotifierProvider<AiAssistantController, List<ChatMessage>>(
  AiAssistantController.new,
);
