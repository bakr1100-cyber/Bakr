/// A single turn in a chat-style LLM conversation.
class LlmMessage {
  const LlmMessage({required this.role, required this.content});

  /// `'user'` or `'assistant'` (Anthropic Messages API roles).
  final String role;
  final String content;
}

/// Thin abstraction over a hosted chat-completion LLM, so
/// [AiAssistantService] can be driven by a real model (e.g. Claude) without
/// hardcoding a specific provider's request/response shape into the
/// conversation logic. A provider implementation only needs to send
/// [systemPrompt] plus [history] and return the model's raw text reply.
abstract class LlmClient {
  Future<String> complete({
    required String systemPrompt,
    required List<LlmMessage> history,
  });
}

/// Thrown by an [LlmClient] implementation on a network/auth/parsing
/// failure. Callers (see `AiAssistantService`) should catch this and fall
/// back to the rule-based assistant rather than let it surface to the UI.
class LlmClientException implements Exception {
  LlmClientException(this.message);

  final String message;

  @override
  String toString() => 'LlmClientException: $message';
}
