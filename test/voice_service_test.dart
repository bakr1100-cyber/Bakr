import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marocfly_ai/services/voice_service.dart';

void main() {
  // VoiceService constructs a FlutterTts() (a MethodChannel-backed plugin)
  // even though these tests only exercise the pure cloud-TTS-routing
  // logic - without a bound test environment, that constructor itself
  // throws before any test body even runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceService cloud TTS routing', () {
    test('attempts the cloud voice for a MeloTTS-supported language (French)', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(
          proxyBaseUrl: 'https://proxy.example', client: client, enableCloudTts: true);

      await voice.speak('Bonjour', locale: 'fr-FR');

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/ai/tts');
    });

    test('attempts the cloud voice for English too', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(
          proxyBaseUrl: 'https://proxy.example', client: client, enableCloudTts: true);

      await voice.speak('Hello', locale: 'en-US');

      expect(requests, hasLength(1));
    });

    test('skips the cloud voice for German - MeloTTS has no German support', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(
          proxyBaseUrl: 'https://proxy.example', client: client, enableCloudTts: true);

      await voice.speak('Hallo', locale: 'de-DE');

      expect(requests, isEmpty);
    });

    test('skips the cloud voice for Darija/Arabic - MeloTTS has no support', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(
          proxyBaseUrl: 'https://proxy.example', client: client, enableCloudTts: true);

      await voice.speak('مرحبا', locale: 'ar-MA');

      expect(requests, isEmpty);
    });

    test('skips the cloud voice entirely when no proxy is configured', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      });
      final voice = VoiceService(client: client, enableCloudTts: true);

      await voice.speak('Bonjour', locale: 'fr-FR');

      expect(requests, isEmpty);
    });

    test('sends the text and short-form language code in the request body', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(
          proxyBaseUrl: 'https://proxy.example', client: client, enableCloudTts: true);

      await voice.speak('Bonjour tout le monde', locale: 'fr-FR');

      final body = requests.single.body;
      expect(body, contains('"text":"Bonjour tout le monde"'));
      expect(body, contains('"lang":"fr"'));
    });

    test('is OFF by default - MeloTTS has never once returned audio, so the app must not '
        'spend a doomed round-trip before falling back to the native voice', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      // Note: no enableCloudTts argument - this is what the real app builds.
      final voice = VoiceService(proxyBaseUrl: 'https://proxy.example', client: client);

      await voice.speak('Bonjour', locale: 'fr-FR');

      expect(requests, isEmpty);
    });
  });

  group('picking the best installed voice', () {
    // Names taken from what Apple actually reports on iOS/macOS.
    const appleGerman = [
      {'name': 'Anna', 'locale': 'de-DE'},
      {'name': 'Helena (Enhanced)', 'locale': 'de-DE'},
      {'name': 'Martin (Compact)', 'locale': 'de-DE'},
    ];

    test('prefers an Enhanced voice over the plain default the engine would have used', () {
      final best = pickBestVoice(appleGerman, 'de-DE', true);

      expect(best?['name'], 'Helena (Enhanced)');
    });

    test('prefers Premium over Enhanced', () {
      final best = pickBestVoice([
        {'name': 'Helena (Enhanced)', 'locale': 'de-DE'},
        {'name': 'Anna (Premium)', 'locale': 'de-DE'},
      ], 'de-DE', true);

      expect(best?['name'], 'Anna (Premium)');
    });

    test('never picks one of Apple\'s novelty voices, even when marked Enhanced', () {
      final best = pickBestVoice([
        {'name': 'Zarvox (Enhanced)', 'locale': 'de-DE'},
        {'name': 'Anna', 'locale': 'de-DE'},
      ], 'de-DE', true);

      expect(best?['name'], 'Anna');
    });

    test('honours the female/male preference when quality is equal', () {
      const voices = [
        {'name': 'Thomas (Enhanced)', 'locale': 'fr-FR'},
        {'name': 'Amelie (Enhanced)', 'locale': 'fr-FR'},
      ];

      expect(pickBestVoice(voices, 'fr-FR', true)?['name'], 'Amelie (Enhanced)');
      expect(pickBestVoice(voices, 'fr-FR', false)?['name'], 'Thomas (Enhanced)');
    });

    test('quality beats the gender preference - an enhanced male voice is better than '
        'a compact female one even when a female voice was asked for', () {
      final best = pickBestVoice([
        {'name': 'Anna (Compact)', 'locale': 'de-DE'},
        {'name': 'Martin (Enhanced)', 'locale': 'de-DE'},
      ], 'de-DE', true);

      expect(best?['name'], 'Martin (Enhanced)');
    });

    test('accepts a same-language voice from another region rather than giving up', () {
      final best = pickBestVoice([
        {'name': 'Petra (Enhanced)', 'locale': 'de-AT'},
      ], 'de-DE', true);

      expect(best?['name'], 'Petra (Enhanced)');
    });

    test('prefers the exact locale when quality is otherwise equal', () {
      final best = pickBestVoice([
        {'name': 'Petra (Enhanced)', 'locale': 'de-AT'},
        {'name': 'Helena (Enhanced)', 'locale': 'de-DE'},
      ], 'de-DE', true);

      expect(best?['name'], 'Helena (Enhanced)');
    });

    test('ignores voices for other languages entirely', () {
      expect(pickBestVoice([
        {'name': 'Samantha (Enhanced)', 'locale': 'en-US'},
      ], 'ar-MA', true), isNull);
    });

    test('leaves the engine default alone when nothing about the voice is better', () {
      // No quality marker, not an exact locale match, and the wrong gender
      // for the requested preference - nothing here beats what the engine
      // already chose, so overriding would be churn rather than an upgrade.
      expect(pickBestVoice([
        {'name': 'Majed', 'locale': 'ar-SA'},
      ], 'ar-MA', true), isNull);
    });

    test('still switches for the gender preference alone, since that is a real '
        'preference the user set even when no quality marker distinguishes the voices', () {
      expect(
        pickBestVoice([
          {'name': 'Majed', 'locale': 'ar-SA'},
        ], 'ar-MA', false)?['name'],
        'Majed',
      );
    });

    test('survives the malformed entries a browser can report', () {
      expect(
        () => pickBestVoice([
          {'name': null, 'locale': 'de-DE'},
          {'locale': 'de-DE'},
          'not a map',
          {'name': 'Helena (Enhanced)', 'locale': 'de-DE'},
        ], 'de-DE', true),
        returnsNormally,
      );
      expect(
        pickBestVoice([
          {'name': null, 'locale': 'de-DE'},
          'not a map',
          {'name': 'Helena (Enhanced)', 'locale': 'de-DE'},
        ], 'de-DE', true)?['name'],
        'Helena (Enhanced)',
      );
    });
  });

  group('VoiceService cloud STT fallback', () {
    // These tests never call init(), so `_speechAvailable` stays at its
    // default false - the same state a browser with no Web Speech API
    // support would be in, exercising the fallback path without needing to
    // fake platform-level speech recognition.

    test('isAvailable reflects the cloud fallback even before init(), independent of native support', () {
      final withProxy = VoiceService(proxyBaseUrl: 'https://proxy.example');
      final withoutProxy = VoiceService();

      expect(withProxy.isAvailable, isTrue);
      expect(withoutProxy.isAvailable, isFalse);
    });

    test('startListening does not throw and never calls back when no proxy is configured', () async {
      final voice = VoiceService();
      var callbackFired = false;

      await voice.startListening(onResult: (_, __) => callbackFired = true);

      expect(callbackFired, isFalse);
    });

    test('startListening does not throw when a proxy is configured but recording is unavailable '
        '(no platform binding in a plain test environment, same as a real permission denial)', () async {
      final voice = VoiceService(
        proxyBaseUrl: 'https://proxy.example',
        client: MockClient((request) async => http.Response('{}', 200)),
      );
      var callbackFired = false;

      await voice.startListening(onResult: (_, __) => callbackFired = true);
      await voice.stopListening();

      expect(callbackFired, isFalse);
      expect(voice.isListening, isFalse);
    });
  });
}
