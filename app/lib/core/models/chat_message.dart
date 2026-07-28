enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final ChatRole role;
  final String text;
  final DateTime timestamp;
}
