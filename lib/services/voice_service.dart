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
      listenOptions: SpeechListenOptions(localeId: localeId),
    );
  }

  Future<void> stopListening() => _speechToText.stop();

  /// Web browsers (notably Safari on iOS/iPadOS) only allow speech
  /// synthesis to actually produce sound when `speak()` is called
  /// synchronously inside a user gesture (a tap) - any `speak()` call made
  /// after an `await` (e.g. waiting for the AI's reply over the network,
  /// which is every reply in this app) gets silently swallowed, with no
  /// error. Call this synchronously as the very first line of a button's
  /// tap handler, before any `await`, to unlock speech synthesis for the
  /// rest of that handler - even once it goes async afterwards.
  void unlockSpeechForThisGesture() {
    // Fire-and-forget on purpose: an empty utterance makes no sound, this
    // exists only to happen inside the synchronous gesture call stack.
    // ignore: discarded_futures
    _tts.speak(' ');
  }

  /// [useFemaleVoice] toggles between the two voice options called for in
  /// the brief; concrete voice selection is platform/engine dependent, so
  /// this maps to pitch as a reasonable default across TTS engines.
  ///
  /// [locale] (e.g. `'ar-MA'`, `'de-DE'` - see [AppLanguageCode.speechLocale])
  /// must be set explicitly, or the TTS engine keeps speaking in whatever
  /// language it was last configured with (or its OS default) regardless
  /// of the app's selected language.
  Future<void> speak(String text, {bool useFemaleVoice = true, String? locale}) async {
    if (locale != null) await _tts.setLanguage(locale);
    await _tts.setPitch(useFemaleVoice ? 1.05 : 0.85);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
}
