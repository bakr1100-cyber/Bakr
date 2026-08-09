import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/localization/app_localizations.dart';
import '../models/chat_message.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../services/ai_assistant_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({AiAssistantService? assistantService, AppLanguage language = AppLanguage.ary})
      : _assistant = assistantService ?? AiAssistantService() {
    _messages.add(_greeting(language));
  }

  final AiAssistantService _assistant;
  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ChatMessage _greeting(AppLanguage language) => ChatMessage(
        id: _uuid.v4(),
        sender: ChatSender.assistant,
        text: AppLocalizations(language).t('aiChatGreeting'),
        timestamp: DateTime.now(),
      );

  /// Re-greets in [language] if the conversation hasn't really started yet
  /// (still just the opening greeting) - called when the user picks/changes
  /// their language, since [ChatProvider] is created once for the app's
  /// whole lifetime, before any language may have been chosen yet.
  void setLanguage(AppLanguage language) {
    if (_messages.length > 1) return;
    _messages
      ..clear()
      ..add(_greeting(language));
    notifyListeners();
  }

  TravelIntent _intent = const TravelIntent();
  TravelIntent get intent => _intent;

  List<Itinerary>? _lastResults;
  List<Itinerary>? get lastResults => _lastResults;

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  Future<void> send(String text, {bool wasSpoken = false, AppLanguage language = AppLanguage.ary}) async {
    if (text.trim().isEmpty || _isThinking) return;

    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        sender: ChatSender.user,
        text: text,
        timestamp: DateTime.now(),
        wasSpoken: wasSpoken,
      ),
    );
    _isThinking = true;
    notifyListeners();

    // Without this, any exception anywhere in handleMessage() (NLU parsing,
    // the flight search, the LLM call) would leave _isThinking stuck true
    // forever with no reply ever added - the chat just silently hangs, with
    // no visible error and no way to recover except restarting the app.
    AssistantTurn turn;
    try {
      turn = await _assistant.handleMessage(
        text,
        _intent,
        history: _messages,
        language: language,
      );
    } catch (error) {
      debugPrint('ChatProvider: handleMessage failed ($error).');
      turn = AssistantTurn(
        reply: AppLocalizations(language).t('genericErrorRetry'),
        intent: _intent,
      );
    }
    _intent = turn.intent;
    _lastResults = turn.results ?? _lastResults;

    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        sender: ChatSender.assistant,
        text: turn.reply,
        timestamp: DateTime.now(),
      ),
    );
    _isThinking = false;
    notifyListeners();
  }

  void reset() {
    _intent = const TravelIntent();
    _lastResults = null;
    _messages.clear();
    notifyListeners();
  }
}
