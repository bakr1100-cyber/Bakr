import 'localization/app_localizations.dart';

/// Maps an error code to a friendly, localized message. Handles both:
/// - Firebase Identity Toolkit REST API codes (`EMAIL_EXISTS`,
///   `WEAK_PASSWORD`, ...) - what [AuthProvider] actually talks to now.
/// - The old Firebase Auth JS/Dart SDK's hyphenated codes
///   (`email-already-in-use`, ...) - kept for robustness in case any
///   caller still surfaces one.
///
/// Pulled out of [AuthProvider] as a pure function so it's testable without
/// making a real network call first.
String authErrorMessage(String rawCode, AppLanguage language) {
  // REST errors sometimes come as "WEAK_PASSWORD : Password should be at
  // least 6 characters" - only the part before the colon is the code.
  final code = rawCode.split(':').first.trim();
  final key = switch (code) {
    'EMAIL_EXISTS' || 'email-already-in-use' => 'authErrorEmailInUse',
    'INVALID_EMAIL' || 'invalid-email' => 'authErrorInvalidEmail',
    'WEAK_PASSWORD' || 'weak-password' => 'authErrorWeakPassword',
    'EMAIL_NOT_FOUND' ||
    'INVALID_PASSWORD' ||
    'INVALID_LOGIN_CREDENTIALS' ||
    'user-not-found' ||
    'invalid-credential' ||
    'wrong-password' =>
      'authErrorWrongCredentials',
    'USER_DISABLED' || 'user-disabled' => 'authErrorUserDisabled',
    'TOO_MANY_ATTEMPTS_TRY_LATER' || 'too-many-requests' => 'authErrorTooManyRequests',
    'network-request-failed' || 'network-error' => 'authErrorNetwork',
    'unauthorized-domain' => 'authErrorUnauthorizedDomain',
    _ => 'authErrorGeneric',
  };
  return AppLocalizations(language).t(key);
}
