enum ChatSender { user, assistant }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.wasSpoken = false,
  });

  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;

  /// True if this message was produced via voice input/output rather than
  /// typed, so the UI can show a mic/speaker glyph next to it.
  final bool wasSpoken;
}
