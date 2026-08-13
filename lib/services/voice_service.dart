import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
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
/// Speech-to-text primarily uses the platform's built-in engine (the
/// `speech_to_text` plugin, wrapping Safari's on-device Web Speech API on
/// this app's main deployed target) - no cloud speech API keys required,
/// and live partial transcripts as the user speaks. When that engine isn't
/// available at all (e.g. a browser with no Web Speech API support), and
/// [proxyBaseUrl] is configured, [startListening] falls back to recording
/// audio and transcribing it via the Worker's `/ai/stt` (Whisper) route
/// instead - no live partial text in that case, the transcript only
/// arrives once recording stops.
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
  // Lazy: constructing an AudioPlayer/AudioRecorder touches a platform
  // channel immediately, which both isn't needed until the cloud path is
  // actually reached and would blow up eagerly in a plain unit-test
  // environment (no platform bindings registered) even for tests that
  // never touch audio at all.
  late final AudioPlayer _cloudPlayer = AudioPlayer();
  late final AudioRecorder _recorder = AudioRecorder();
  bool _speechAvailable = false;
  bool _cloudSttRecording = false;
  void Function(String text, bool isFinal)? _pendingSttCallback;

  Future<bool> init() async {
    _speechAvailable = await _speechToText.initialize();
    await _tts.setSpeechRate(0.48);
    return isAvailable;
  }

  /// True if either the native engine or the cloud fallback (see
  /// [_startCloudRecording]) can plausibly handle voice input - used to
  /// decide whether the mic button does anything at all. Cloud
  /// availability only means a proxy URL is configured; an actual
  /// recording attempt can still fail (e.g. mic permission denied), same
  /// as the native engine can.
  bool get isAvailable => _speechAvailable || _cloudSttAvailable;
  bool get isListening => _speechToText.isListening || _cloudSttRecording;

  bool get _cloudSttAvailable {
    final proxy = _proxyBaseUrl;
    return proxy != null && proxy.isNotEmpty;
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'de-DE',
  }) async {
    if (_speechAvailable) {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: SpeechListenOptions(localeId: localeId),
      );
      return;
    }
    // Fallback for a browser with no native speech recognition at all
    // (e.g. Firefox has no Web Speech API) - this app's primary target,
    // Safari, already has native support and never reaches this path, so
    // it carries no regression risk for the existing, tested experience.
    // Unlike native listening there's no live partial transcript: the mic
    // stays in the "listening" state while recording, and text only
    // arrives once recording stops and the upload+transcribe round-trip
    // completes.
    await _startCloudRecording(onResult);
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      return;
    }
    if (_cloudSttRecording) await _stopCloudRecordingAndTranscribe();
  }

  Future<void> _startCloudRecording(
    void Function(String text, bool isFinal) onResult,
  ) async {
    if (!_cloudSttAvailable) return;
    try {
      if (!await _recorder.hasPermission()) return;
      _pendingSttCallback = onResult;
      _cloudSttRecording = true;
      // AAC/M4A: the format Safari's MediaRecorder actually supports, and
      // one of Whisper's documented accepted input formats on Workers AI.
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: 'voice-input.m4a', // ignored on web - kept for other platforms
      );
    } catch (error) {
      debugPrint('VoiceService: cloud STT recording failed to start ($error).');
      _cloudSttRecording = false;
      _pendingSttCallback = null;
    }
  }

  Future<void> _stopCloudRecordingAndTranscribe() async {
    _cloudSttRecording = false;
    final callback = _pendingSttCallback;
    _pendingSttCallback = null;
    try {
      final path = await _recorder.stop();
      if (path == null || callback == null) return;
      // On web `path` is a blob: URL holding the recorded audio in memory
      // - fetch it back into bytes to upload, same as any other resource.
      final audioBytes = (await _client.get(Uri.parse(path)).timeout(const Duration(seconds: 10))).bodyBytes;
      final response = await _client
          .post(
            Uri.parse('$_proxyBaseUrl/ai/stt'),
            headers: const {'Content-Type': 'application/octet-stream'},
            body: audioBytes,
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['text'] as String?;
      if (text != null && text.trim().isNotEmpty) callback(text, true);
    } catch (error) {
      debugPrint('VoiceService: cloud STT transcription failed ($error).');
    }
  }

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
