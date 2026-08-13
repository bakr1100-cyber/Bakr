import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

/// MeloTTS (see the Worker's `/ai/tts` route) only documents support for
/// these languages - German/Arabic/Darija text sent to it would likely
/// come out badly mispronounced, worse than the native OS voice this app
/// already has working for those. Only attempt the cloud voice for a
/// locale on this list; everything else goes straight to the native
/// engine, no wasted network round-trip either.
const _cloudTtsSupportedLangPrefixes = {'en', 'fr'};

/// Thin wrapper around speech-to-text and text-to-speech so the whole app
/// can be operated by voice.
///
/// Speech-to-text still uses the platform's built-in engine (the
/// `speech_to_text` plugin, wrapping Safari's on-device Web Speech API on
/// this app's only deployed platform) - no cloud speech API keys required
/// for that half, and unlike TTS output there's no cross-language support
/// gap to work around (see below).
///
/// Text-to-speech, when [proxyBaseUrl] is configured (the same Cloudflare
/// Worker URL that already proxies Duffel/the AI chat - see
/// `_duffelProxyUrl` in `app.dart`) and the target language is one MeloTTS
/// actually supports, tries that cloud voice first for a markedly more
/// natural result than `flutter_tts`'s OS-default voice - falling back to
/// the native engine on any failure (network error, unsupported language,
/// proxy not configured, playback error), exactly the same
/// never-worse-than-before degradation every other optional integration
/// in this app follows.
class VoiceService {
  VoiceService({String? proxyBaseUrl, http.Client? client})
      : _proxyBaseUrl = proxyBaseUrl,
        _client = client ?? http.Client();

  final String? _proxyBaseUrl;
  final http.Client _client;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  // Lazy: constructing an AudioPlayer touches a platform channel
  // immediately, which both isn't needed until the cloud voice path is
  // actually reached and would blow up eagerly in a plain unit-test
  // environment (no platform bindings registered) even for tests that
  // never touch audio playback at all.
  late final AudioPlayer _cloudPlayer = AudioPlayer();
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
  /// synthesis/audio playback to actually produce sound when triggered
  /// synchronously inside a user gesture (a tap) - any playback started
  /// after an `await` (e.g. waiting for the AI's reply over the network,
  /// which is every reply in this app) gets silently swallowed, with no
  /// error. Call this synchronously as the very first line of a button's
  /// tap handler, before any `await`, to unlock both engines for the rest
  /// of that handler - even once it goes async afterwards.
  void unlockSpeechForThisGesture() {
    // Fire-and-forget on purpose: an empty/near-silent utterance makes no
    // (meaningful) sound, this exists only to happen inside the
    // synchronous gesture call stack.
    // ignore: discarded_futures
    _tts.speak(' ');
    // ignore: discarded_futures
    _cloudPlayer.play(_silentWavSource, volume: 0);
  }

  /// [useFemaleVoice] toggles between the two voice options called for in
  /// the brief; concrete voice selection is platform/engine dependent, so
  /// this maps to pitch as a reasonable default across TTS engines (the
  /// cloud voice doesn't support a pitch knob, so this only affects the
  /// native fallback).
  ///
  /// [locale] (e.g. `'ar-MA'`, `'de-DE'` - see [AppLanguageCode.speechLocale])
  /// must be set explicitly, or the TTS engine keeps speaking in whatever
  /// language it was last configured with (or its OS default) regardless
  /// of the app's selected language.
  Future<void> speak(String text, {bool useFemaleVoice = true, String? locale}) async {
    final cloudLang = _cloudTtsLang(locale);
    if (cloudLang != null && await _speakViaCloud(text, cloudLang)) return;

    try {
      if (locale != null) await _tts.setLanguage(locale);
      await _tts.setPitch(useFemaleVoice ? 1.05 : 0.85);
      await _tts.speak(text);
    } catch (error) {
      // Last resort already exhausted (cloud voice unavailable/failed, and
      // now the native engine itself is erroring) - fail silently rather
      // than crash whatever async callback called this.
      debugPrint('VoiceService: native TTS failed ($error).');
    }
  }

  String? _cloudTtsLang(String? locale) {
    if (_proxyBaseUrl == null || _proxyBaseUrl.isEmpty || locale == null) return null;
    final prefix = locale.split('-').first.toLowerCase();
    return _cloudTtsSupportedLangPrefixes.contains(prefix) ? prefix : null;
  }

  /// Returns whether the cloud voice actually played, so the caller knows
  /// whether it still needs to fall back to the native engine.
  Future<bool> _speakViaCloud(String text, String lang) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_proxyBaseUrl/ai/tts'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'lang': lang}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final audioBase64 = data['audio'] as String?;
      if (audioBase64 == null || audioBase64.isEmpty) return false;

      await _cloudPlayer.play(BytesSource(base64Decode(audioBase64)));
      return true;
    } catch (error) {
      debugPrint('VoiceService: cloud TTS failed, falling back to native ($error).');
      return false;
    }
  }

  Future<void> stopSpeaking() => Future.wait([_tts.stop(), _cloudPlayer.stop()]);
}

/// The shortest possible valid WAV file (a handful of silent PCM
/// samples), used only to unlock autoplay - see
/// [VoiceService.unlockSpeechForThisGesture].
final _silentWavSource = BytesSource(
  Uint8List.fromList([
    0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45, //
    0x66, 0x6d, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
    0x44, 0xac, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00, 0x02, 0x00, 0x10, 0x00,
    0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00,
  ]),
);
