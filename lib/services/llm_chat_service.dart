import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// One message in the format Workers AI (and most chat-completion APIs)
/// expect: `{"role": "system"|"user"|"assistant", "content": "..."}`.
class LlmMessage {
  const LlmMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Calls the free, open-source LLM (Llama 3.1 8B Instruct) running on
/// Cloudflare Workers AI, proxied through the same Worker that already
/// hides the Duffel API key (see `cloudflare-worker/`) - so this needs no
/// separate signup or API key of its own, and stays within Workers AI's
/// free daily quota.
///
/// This is used only to *phrase* replies conversationally - all
/// travel-intent extraction and the actual flight search stay on the
/// deterministic `NluService`/`FlightSearchService` path (see
/// [AiAssistantService]), so the app keeps working exactly as before even
/// if this call fails, times out, or the free quota runs out for the day.
class LlmChatService {
  LlmChatService({required String proxyBaseUrl, http.Client? client})
      : _baseUrl = proxyBaseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  bool get isConfigured => _baseUrl.isNotEmpty;

  /// [jsonMode] asks the backend to guarantee a valid-JSON reply where the
  /// underlying model supports it (currently only when the proxy is
  /// configured to use Mistral - a no-op otherwise) - used by
  /// [AiAssistantService]'s intent extraction, which needs to parse the
  /// reply as structured data rather than display it as-is.
  Future<String?> reply(List<LlmMessage> messages, {bool jsonMode = false}) async {
    if (!isConfigured) return null;

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/ai/chat'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': [for (final m in messages) m.toJson()],
              if (jsonMode) 'json_mode': true,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['reply'] as String?;
      return (text == null || text.trim().isEmpty) ? null : text.trim();
    } catch (error) {
      debugPrint('LlmChatService: falling back to template reply ($error).');
      return null;
    }
  }
}
