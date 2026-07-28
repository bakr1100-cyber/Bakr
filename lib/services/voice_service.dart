import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around on-device speech-to-text and text-to-speech so the
/// whole app can be operated by voice. Uses the platform's built-in speech
/// engines via the `speech_to_text` / `flutter_tts` plugins - no cloud
/// speech API keys required for the base experience. For markedly better
/// Darija recognition/synthesis than the OS engines offer, point this at a
/// cloud provider (e.g. ElevenLabs for TTS, a Whisper-family model for STT)
/// behind the same interface.
class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;

  Future<bool> init() async {
    _speechAvailable = await _speechToText.initialize();
    await _tts.setSpeechRate(0.48);
    return _speechAvailable;
  }

  bool get isAvailable => _speechAvailable;
  bool get isListening => _speechToText.isListening;

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'de-DE',
  }) async {
    if (!_speechAvailable) return;
    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: localeId,
    );
  }

  Future<void> stopListening() => _speechToText.stop();

  /// [useFemaleVoice] toggles between the two voice options called for in
  /// the brief; concrete voice selection is platform/engine dependent, so
  /// this maps to pitch as a reasonable default across TTS engines.
  Future<void> speak(String text, {bool useFemaleVoice = true}) async {
    await _tts.setPitch(useFemaleVoice ? 1.05 : 0.85);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
}
