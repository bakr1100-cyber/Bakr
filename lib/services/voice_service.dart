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

/// Whether to try the cloud voice at all.
///
/// Currently **off**: MeloTTS on Workers AI has failed on every single
/// deploy smoke test so far, for both `en` and `fr`, with three different
/// errors (`3040: Capacity temporarily exceeded`, `3043: Internal server
/// error`, `8002: Invalid input` - the last one is a known, undocumented
/// per-language gap, see cloudflare/cloudflare-docs#23308). It has never
/// once returned audio.
///
/// Leaving it enabled isn't harmless: every French/English reply would
/// first spend a network round-trip failing before the native voice starts
/// speaking, so the user just waits longer for the same voice they already
/// had. The whole path stays wired up and tested behind this flag - flip
/// it back to `true` once the deploy smoke test starts reporting
/// `lang=... OK`, no other change needed.
const _cloudTtsEnabledByDefault = false;

/// Apple ships these alongside the real ones and they are, without
/// exception, unusable for reading out a flight price - they must never be
/// picked even if they happen to be the only "enhanced" voice available.
const _noveltyVoiceNames = {
  'albert', 'bad news', 'bahh', 'bells', 'boing', 'bubbles', 'cellos',
  'good news', 'jester', 'organ', 'superstar', 'trinoids', 'whisper',
  'wobble', 'zarvox', //
};

/// Used only to honour the app's female/male voice preference - engines
/// don't expose a gender field, so this matches the standard Apple/Google
/// voice names for the five languages this app speaks. Missing a name here
/// costs nothing: the voice is still chosen on quality first, this only
/// breaks ties.
const _femaleVoiceNames = {
  'amelie', 'amélie', 'anna', 'aurelie', 'aurélie', 'audrey', 'carmit',
  'ellen', 'fiona', 'helena', 'karen', 'katya', 'laila', 'lana', 'lekha',
  'marie', 'maryam', 'moira', 'monica', 'mounia', 'nora', 'paulina',
  'petra', 'samantha', 'sara', 'serena', 'sinji', 'susan', 'tessa',
  'veena', 'victoria', 'yelda', 'zosia', 'zuzana', //
};

/// Picks the best-sounding installed voice for [locale] out of the raw
/// `[{name, locale}]` list a TTS engine reports, or null when none of them
/// beats leaving the engine's own default alone.
///
/// Split out as a plain function purely so it can be tested: everything
/// else in [VoiceService] needs a live platform channel, while this - the
/// part that actually decides how the app sounds - is pure data.
@visibleForTesting
Map<String, String>? pickBestVoice(List<dynamic> raw, String locale, bool preferFemale) {
  final language = locale.split('-').first.toLowerCase();
  final candidates = <Map<String, String>>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final name = entry['name']?.toString();
    final voiceLocale = entry['locale']?.toString();
    if (name == null || voiceLocale == null) continue;
    // Match on the language family, not the exact locale: a de-AT voice is
    // a far better German than no German at all. Exact matches are still
    // preferred, via the score below.
    if (!voiceLocale.toLowerCase().startsWith(language)) continue;
    candidates.add({'name': name, 'locale': voiceLocale});
  }
  if (candidates.isEmpty) return null;

  candidates.sort((a, b) =>
      _voiceScore(b, locale, preferFemale).compareTo(_voiceScore(a, locale, preferFemale)));
  final best = candidates.first;
  // A score of 0 means nothing distinguishes this voice from the default
  // the engine already picked - changing it would be churn, not an upgrade.
  return _voiceScore(best, locale, preferFemale) > 0 ? best : null;
}

/// Higher is better. Quality markers dominate deliberately: the gap
/// between a compact and an enhanced voice is far more audible than the
/// gap between two voices of the same tier.
int _voiceScore(Map<String, String> voice, String locale, bool preferFemale) {
  final name = voice['name']!.toLowerCase();
  final voiceLocale = voice['locale']!.toLowerCase();
  var score = 0;

  // Apple/Google mark their better voices in the name itself...
  if (name.contains('premium')) score += 100;
  if (name.contains('enhanced')) score += 80;
  if (name.contains('neural')) score += 80;
  if (name.contains('siri')) score += 60;
  // ...and their thinnest one, likewise.
  if (name.contains('compact')) score -= 50;
  // Apple ships joke voices that will cheerfully read out a flight price
  // in a cartoon warble - never pick one, even if it's the only
  // "enhanced" entry in the list.
  if (_noveltyVoiceNames.any(name.contains)) score -= 500;

  if (voiceLocale == locale.toLowerCase()) score += 20;
  if (_femaleVoiceNames.any(name.contains) == preferFemale) score += 10;

  return score;
}

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
  VoiceService({
    String? proxyBaseUrl,
    http.Client? client,
    bool enableCloudTts = _cloudTtsEnabledByDefault,
  })  : _proxyBaseUrl = proxyBaseUrl,
        _client = client ?? http.Client(),
        _cloudTtsEnabled = enableCloudTts;

  final String? _proxyBaseUrl;
  final bool _cloudTtsEnabled;
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
      if (locale != null) {
        await _tts.setLanguage(locale);
        await _applyBestVoice(locale, useFemaleVoice);
      }
      await _tts.setPitch(useFemaleVoice ? 1.05 : 0.85);
      await _tts.speak(text);
    } catch (error) {
      // Last resort already exhausted (cloud voice unavailable/failed, and
      // now the native engine itself is erroring) - fail silently rather
      // than crash whatever async callback called this.
      debugPrint('VoiceService: native TTS failed ($error).');
    }
  }

  /// Upgrades the voice for [locale] from whatever the engine picked by
  /// default to the best one actually installed on the device.
  ///
  /// This matters more than it sounds: `flutter_tts`'s web implementation
  /// resolves `setLanguage('de-DE')` by taking the *first* voice the
  /// browser happens to list for that language - no quality ranking at
  /// all. On Apple devices that first entry is typically the small
  /// "compact" voice, which is exactly the thin, robotic one; the richer
  /// Enhanced/Premium voice sits further down the same list, already
  /// installed and free. Picking it deliberately is the single biggest
  /// quality win available without any external service.
  ///
  /// Entirely best-effort: any failure, or a device that simply has no
  /// better voice, leaves the engine's own choice untouched.
  Future<void> _applyBestVoice(String locale, bool preferFemale) async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;

      final best = pickBestVoice(raw, locale, preferFemale);
      if (best == null) return;

      await _tts.setVoice({'name': best['name']!, 'locale': best['locale']!});
    } catch (error) {
      debugPrint('VoiceService: could not select a better voice ($error).');
    }
  }

  String? _cloudTtsLang(String? locale) {
    if (!_cloudTtsEnabled) return null;
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
