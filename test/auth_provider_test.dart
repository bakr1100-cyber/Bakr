import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marocfly_ai/core/auth_error_messages.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('authErrorMessage', () {
    // Regression-proofing: every error code this app maps must resolve to
    // a real, localized message rather than silently falling through with
    // the raw code (which would show a user an internal string like
    // "EMAIL_EXISTS" instead of a sentence in their own language).
    test('every known error code (REST and legacy SDK) maps to a localized message', () {
      const codes = [
        // Identity Toolkit REST API codes - what AuthProvider actually sees.
        'EMAIL_EXISTS',
        'INVALID_EMAIL',
        'WEAK_PASSWORD',
        'WEAK_PASSWORD : Password should be at least 6 characters',
        'EMAIL_NOT_FOUND',
        'INVALID_PASSWORD',
        'INVALID_LOGIN_CREDENTIALS',
        'USER_DISABLED',
        'TOO_MANY_ATTEMPTS_TRY_LATER',
        // Legacy Firebase Auth SDK codes - kept mapped for robustness.
        'email-already-in-use',
        'invalid-email',
        'weak-password',
        'user-not-found',
        'invalid-credential',
        'wrong-password',
        'user-disabled',
        'too-many-requests',
        'network-request-failed',
        'unauthorized-domain',
        'some-unrecognized-code',
      ];

      for (final language in AppLanguage.values) {
        for (final code in codes) {
          final message = authErrorMessage(code, language);
          expect(message, isNotEmpty, reason: 'code=$code language=${language.code}');
          expect(message, isNot(code), reason: 'should be translated, not the raw code');
        }
      }
    });

    test('REST and legacy codes for the same situation give the same message', () {
      final expected = authErrorMessage('wrong-password', AppLanguage.en);
      expect(authErrorMessage('user-not-found', AppLanguage.en), expected);
      expect(authErrorMessage('invalid-credential', AppLanguage.en), expected);
      expect(authErrorMessage('EMAIL_NOT_FOUND', AppLanguage.en), expected);
      expect(authErrorMessage('INVALID_PASSWORD', AppLanguage.en), expected);
      expect(authErrorMessage('INVALID_LOGIN_CREDENTIALS', AppLanguage.en), expected);
    });

    test('a WEAK_PASSWORD detail suffix after the colon is ignored', () {
      expect(
        authErrorMessage('WEAK_PASSWORD : Password should be at least 6 characters',
            AppLanguage.en),
        authErrorMessage('WEAK_PASSWORD', AppLanguage.en),
      );
    });

    test('an unrecognized code falls back to the generic error message', () {
      expect(
        authErrorMessage('some-unrecognized-code', AppLanguage.de),
        AppLocalizations(AppLanguage.de).t('authErrorGeneric'),
      );
    });
  });

  group('AuthProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('register() sends signUp then sendOobCode, and never leaves the account signed in',
        () async {
      final calledUrls = <String>[];
      final client = MockClient((request) async {
        calledUrls.add(request.url.path);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path.contains('signUp')) {
          expect(body['email'], 'new@example.com');
          expect(body['password'], 'supersecret');
          return http.Response(jsonEncode({'idToken': 'tok-123', 'email': 'new@example.com'}), 200);
        }
        if (request.url.path.contains('sendOobCode')) {
          expect(body['requestType'], 'VERIFY_EMAIL');
          expect(body['idToken'], 'tok-123');
          return http.Response(jsonEncode({'email': 'new@example.com'}), 200);
        }
        fail('unexpected request to ${request.url}');
      });
      final auth = AuthProvider(client: client);

      final result = await auth.register(
        email: 'new@example.com',
        password: 'supersecret',
        language: AppLanguage.en,
      );

      expect(result, isA<AuthNeedsVerification>());
      expect(calledUrls, [contains('signUp'), contains('sendOobCode')]);
      expect(auth.isLoggedIn, isFalse, reason: 'must not auto-login an unverified account');
      expect(auth.currentUserEmail, isNull);
    });

    test('register() with an already-used email returns a localized failure', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 400, 'message': 'EMAIL_EXISTS'}
          }),
          400,
        );
      });
      final auth = AuthProvider(client: client);

      final result = await auth.register(
        email: 'taken@example.com',
        password: 'supersecret',
        language: AppLanguage.de,
      );

      expect(result, isA<AuthFailure>());
      expect((result as AuthFailure).message,
          '${authErrorMessage('EMAIL_EXISTS', AppLanguage.de)} [EMAIL_EXISTS]');
    });

    test('signIn() with an unverified email fails without logging in', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('signInWithPassword')) {
          return http.Response(
            jsonEncode({'idToken': 'tok-456', 'email': 'unverified@example.com'}),
            200,
          );
        }
        if (request.url.path.contains('lookup')) {
          return http.Response(
            jsonEncode({
              'users': [
                {'email': 'unverified@example.com', 'emailVerified': false}
              ]
            }),
            200,
          );
        }
        fail('unexpected request to ${request.url}');
      });
      final auth = AuthProvider(client: client);

      final result = await auth.signIn(
        email: 'unverified@example.com',
        password: 'supersecret',
        language: AppLanguage.en,
      );

      expect(result, isA<AuthFailure>());
      expect((result as AuthFailure).message,
          AppLocalizations(AppLanguage.en).t('authErrorEmailNotVerified'));
      expect(auth.isLoggedIn, isFalse);
    });

    test('signIn() with a verified email logs in and persists the session', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('signInWithPassword')) {
          return http.Response(
            jsonEncode({'idToken': 'tok-789', 'email': 'verified@example.com'}),
            200,
          );
        }
        if (request.url.path.contains('lookup')) {
          return http.Response(
            jsonEncode({
              'users': [
                {'email': 'verified@example.com', 'emailVerified': true}
              ]
            }),
            200,
          );
        }
        fail('unexpected request to ${request.url}');
      });
      final auth = AuthProvider(client: client);
      var notified = false;
      auth.addListener(() => notified = true);

      final result = await auth.signIn(
        email: 'verified@example.com',
        password: 'supersecret',
        language: AppLanguage.en,
      );

      expect(result, isA<AuthSuccess>());
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUserEmail, 'verified@example.com');
      expect(notified, isTrue);

      // Persisted, so a fresh AuthProvider picks the session back up.
      final restored = AuthProvider(client: client);
      await restored.load();
      expect(restored.isLoggedIn, isTrue);
      expect(restored.currentUserEmail, 'verified@example.com');
    });

    test('signIn() with the wrong password returns a localized failure and does not log in',
        () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 400, 'message': 'INVALID_LOGIN_CREDENTIALS'}
          }),
          400,
        );
      });
      final auth = AuthProvider(client: client);

      final result = await auth.signIn(
        email: 'someone@example.com',
        password: 'wrong',
        language: AppLanguage.fr,
      );

      expect(result, isA<AuthFailure>());
      expect((result as AuthFailure).message,
          '${authErrorMessage('INVALID_LOGIN_CREDENTIALS', AppLanguage.fr)} [INVALID_LOGIN_CREDENTIALS]');
      expect(auth.isLoggedIn, isFalse);
    });

    test('signOut() clears both in-memory state and the persisted session', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('signInWithPassword')) {
          return http.Response(jsonEncode({'idToken': 't', 'email': 'x@example.com'}), 200);
        }
        return http.Response(
          jsonEncode({
            'users': [
              {'email': 'x@example.com', 'emailVerified': true}
            ]
          }),
          200,
        );
      });
      final auth = AuthProvider(client: client);
      await auth.signIn(email: 'x@example.com', password: 'p', language: AppLanguage.en);
      expect(auth.isLoggedIn, isTrue);

      await auth.signOut();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUserEmail, isNull);
      final restored = AuthProvider(client: client);
      await restored.load();
      expect(restored.isLoggedIn, isFalse);
    });
  });
}
