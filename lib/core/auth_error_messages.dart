import 'localization/app_localizations.dart';

/// Maps a Firebase Auth error code
/// (https://firebase.google.com/docs/auth/admin/errors) to a friendly,
/// localized message. Pulled out of [AuthProvider] as a pure function so it
/// can be tested without ever constructing a real `FirebaseAuth` instance.
String authErrorMessage(String code, AppLanguage language) {
  final key = switch (code) {
    'email-already-in-use' => 'authErrorEmailInUse',
    'invalid-email' => 'authErrorInvalidEmail',
    'weak-password' => 'authErrorWeakPassword',
    'user-not-found' || 'invalid-credential' || 'wrong-password' => 'authErrorWrongCredentials',
    'user-disabled' => 'authErrorUserDisabled',
    'too-many-requests' => 'authErrorTooManyRequests',
    'network-request-failed' => 'authErrorNetwork',
    'unauthorized-domain' => 'authErrorUnauthorizedDomain',
    _ => 'authErrorGeneric',
  };
  return AppLocalizations(language).t(key);
}
