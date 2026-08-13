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
      final voice = VoiceService(proxyBaseUrl: 'https://proxy.example', client: client);

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
      final voice = VoiceService(proxyBaseUrl: 'https://proxy.example', client: client);

      await voice.speak('Hello', locale: 'en-US');

      expect(requests, hasLength(1));
    });

    test('skips the cloud voice for German - MeloTTS has no German support', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(proxyBaseUrl: 'https://proxy.example', client: client);

      await voice.speak('Hallo', locale: 'de-DE');

      expect(requests, isEmpty);
    });

    test('skips the cloud voice for Darija/Arabic - MeloTTS has no support', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(proxyBaseUrl: 'https://proxy.example', client: client);

      await voice.speak('مرحبا', locale: 'ar-MA');

      expect(requests, isEmpty);
    });

    test('skips the cloud voice entirely when no proxy is configured', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      });
      final voice = VoiceService(client: client);

      await voice.speak('Bonjour', locale: 'fr-FR');

      expect(requests, isEmpty);
    });

    test('sends the text and short-form language code in the request body', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"error":"no_audio"}', 502);
      });
      final voice = VoiceService(proxyBaseUrl: 'https://proxy.example', client: client);

      await voice.speak('Bonjour tout le monde', locale: 'fr-FR');

      final body = requests.single.body;
      expect(body, contains('"text":"Bonjour tout le monde"'));
      expect(body, contains('"lang":"fr"'));
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
