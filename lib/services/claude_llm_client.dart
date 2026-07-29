import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_client.dart';

/// [LlmClient] backed by Anthropic's Claude Messages API
/// (https://docs.claude.com/en/api/messages).
///
/// Mirrors the `DuffelFlightApi`/`DuffelFlightPriceSource` pattern used for
/// flight data elsewhere in this app: pass [apiKey] to call Anthropic
/// directly (only safe for builds that never ship publicly, e.g. a native
/// app you run locally), or [proxyBaseUrl] to call the `cloudflare-worker/`
/// proxy instead, which holds the real key server-side so a public web
/// build never embeds it - see "Real AI agent (Claude)" in README.md.
class ClaudeLlmClient implements LlmClient {
  ClaudeLlmClient({
    String? apiKey,
    String? proxyBaseUrl,
    this.model = 'claude-sonnet-5',
    http.Client? client,
  })  : _apiKey = apiKey,
        _baseUrl = proxyBaseUrl ?? _defaultBaseUrl,
        _client = client ?? http.Client();

  static const _defaultBaseUrl = 'https://api.anthropic.com';
  static const _apiVersion = '2023-06-01';

  final String? _apiKey;
  final String _baseUrl;
  final String model;
  final http.Client _client;

  @override
  Future<String> complete({
    required String systemPrompt,
    required List<LlmMessage> history,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/messages'),
            headers: _headers,
            body: jsonEncode({
              'model': model,
              'max_tokens': 1024,
              'system': systemPrompt,
              'messages': [
                for (final m in history) {'role': m.role, 'content': m.content},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 400) {
        throw LlmClientException('Claude API error ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['content'] as List?;
      if (content == null || content.isEmpty) {
        throw LlmClientException('Claude API returned no content blocks');
      }
      final text = (content.first as Map<String, dynamic>)['text'] as String?;
      if (text == null) {
        throw LlmClientException('Claude API returned a non-text content block');
      }
      return text;
    } on LlmClientException {
      rethrow;
    } catch (error) {
      throw LlmClientException(error.toString());
    }
  }

  Map<String, String> get _headers => {
        if (_apiKey != null) 'x-api-key': _apiKey,
        'anthropic-version': _apiVersion,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void close() => _client.close();
}
