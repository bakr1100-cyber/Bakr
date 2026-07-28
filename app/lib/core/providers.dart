import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline/offline_cache.dart';
import 'services/flight_provider.dart';
import 'services/llm_client.dart';
import 'services/voice_clients.dart';

/// Central place where external-service interfaces are bound to their
/// (currently mock) implementations. Swapping a provider's implementation
/// here is the only change needed to move a feature from mock data to a
/// real backend integration.
final flightProviderProvider = Provider<FlightProvider>((ref) {
  return MockFlightProvider();
});

final llmClientProvider = Provider<LlmClient>((ref) {
  return MockLlmClient();
});

final sttClientProvider = Provider<SttClient>((ref) {
  return MockSttClient();
});

final ttsClientProvider = Provider<TtsClient>((ref) {
  return MockTtsClient();
});

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return InMemoryOfflineCache();
});
