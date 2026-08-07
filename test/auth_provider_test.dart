import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/core/auth_error_messages.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';

void main() {
  group('authErrorMessage', () {
    // Regression-proofing: every Firebase Auth error code this app maps
    // must resolve to a real, localized message rather than silently
    // falling through with the raw code (which would show a user an
    // English/internal string like "invalid-credential" instead of a
    // sentence in their own language).
    test('every known Firebase Auth error code maps to a localized message', () {
      const codes = [
        'email-already-in-use',
        'invalid-email',
        'weak-password',
        'user-not-found',
        'invalid-credential',
        'wrong-password',
        'user-disabled',
        'too-many-requests',
        'network-request-failed',
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

    test('user-not-found, invalid-credential, and wrong-password all give the same message', () {
      final expected = authErrorMessage('wrong-password', AppLanguage.en);
      expect(authErrorMessage('user-not-found', AppLanguage.en), expected);
      expect(authErrorMessage('invalid-credential', AppLanguage.en), expected);
    });

    test('an unrecognized code falls back to the generic error message', () {
      expect(
        authErrorMessage('some-unrecognized-code', AppLanguage.de),
        AppLocalizations(AppLanguage.de).t('authErrorGeneric'),
      );
    });
  });
}
