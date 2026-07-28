import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../services/ai_assistant_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({AiAssistantService? assistantService})
      : _assistant = assistantService ?? AiAssistantService() {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        sender: ChatSender.assistant,
        text: 'Marhba! Wohin möchtest du reisen? Du kannst mir schreiben oder '
            'sprechen - auf Darija, Arabisch, Deutsch, Französisch oder Englisch.',
        timestamp: DateTime.now(),
      ),
    );
  }

  final AiAssistantService _assistant;
  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  TravelIntent _intent = const TravelIntent();
  TravelIntent get intent => _intent;

  List<Itinerary>? _lastResults;
  List<Itinerary>? get lastResults => _lastResults;

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  Future<void> send(String text, {bool wasSpoken = false}) async {
    if (text.trim().isEmpty) return;

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

    final turn = await _assistant.handleMessage(text, _intent);
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
