/// Abstraction over speech-to-text. A real implementation would call a
/// cloud STT provider (Darija/Arabic support is inconsistent on-device).
abstract class SttClient {
  /// Starts listening and resolves with the recognized text once the user
  /// stops speaking.
  Future<String> listen();
}

/// Abstraction over text-to-speech, with a male/female voice choice per the
/// product requirement.
enum VoiceGender { male, female }

abstract class TtsClient {
  Future<void> speak(String text, {VoiceGender voice = VoiceGender.female});
}

/// Stub implementations used until a real STT/TTS provider (e.g. Azure or
/// Google Cloud Speech) is configured. [MockSttClient.listen] returns a
/// canned transcript so the voice UI flow can be exercised without a
/// microphone permission or network call.
class MockSttClient implements SttClient {
  @override
  Future<String> listen() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return 'Bghit arkhass vol l Fès.';
  }
}

class MockTtsClient implements TtsClient {
  @override
  Future<void> speak(
    String text, {
    VoiceGender voice = VoiceGender.female,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
