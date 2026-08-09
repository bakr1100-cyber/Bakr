import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_error_messages.dart';
import '../core/localization/app_localizations.dart';
import '../firebase_options.dart';

/// Outcome of [AuthProvider.register] or [AuthProvider.signIn]. A plain
/// `String?` (null = success) doesn't leave room for the third case that
/// [register] needs: it succeeded, but the account isn't usable yet until
/// the verification email is confirmed.
sealed class AuthAttemptResult {
  const AuthAttemptResult();
}

/// Signed in successfully - [AuthProvider.currentUserEmail] is now set.
class AuthSuccess extends AuthAttemptResult {
  const AuthSuccess();
}

/// Registration succeeded and a verification email was sent, but the
/// account is deliberately signed back out - it isn't usable until the
/// user confirms via the emailed link, then logs in (not registers) again.
class AuthNeedsVerification extends AuthAttemptResult {
  const AuthNeedsVerification();
}

class AuthFailure extends AuthAttemptResult {
  const AuthFailure(this.message);

  /// Already localized - safe to show directly.
  final String message;
}

/// Email/password account login - talks to Firebase's Identity Toolkit
/// REST API (https://cloud.google.com/identity-platform/docs/reference/rest)
/// directly via plain HTTP, deliberately NOT through the `firebase_auth`
/// package.
///
/// Why: `firebase_auth_web` hardcodes `popupRedirectResolver:
/// browserPopupRedirectResolver` into its one-time `initializeAuth()` call
/// (see its `auth.dart`) - every Auth call, including plain email/password,
/// therefore tries to open a cross-origin iframe channel to the project's
/// `authDomain` for popup/redirect session sync we never use. On iOS
/// WebKit (Safari AND Chrome-for-iOS, both WebKit under the hood) that
/// channel gets blocked outright by cross-site-tracking prevention -
/// observed live as `auth/channel-error` on every single attempt,
/// regardless of browser, private-mode, or persistence settings, because
/// the resolver is wired in before any of those could matter. There is no
/// public Dart API to opt out of it. The REST API has no iframe, no
/// IndexedDB, no popup/redirect concept at all, so none of this applies.
///
/// Preferences and price alerts sync to the account via [AccountSyncService]
/// once logged in (see that class + `CloudSyncService`), which needs a
/// valid (non-expired) ID token for every Firestore call - [getValidIdToken]
/// is what makes that safe across a session that outlives the ID token's
/// 1-hour lifetime, by exchanging the refresh token for a new one on demand.
///
/// Registration requires email verification before the account can log in
/// (the standard SaaS pattern: register -> verification email -> click
/// link -> log in) - [register] never persists a session, specifically so
/// a freshly registered, unverified account is never treated as "logged
/// in".
class AuthProvider extends ChangeNotifier {
  AuthProvider({http.Client? client}) : _client = client ?? http.Client();

  static final _apiKey = DefaultFirebaseOptions.web.apiKey;
  static const _signUpUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp';
  static const _signInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';
  static const _lookupUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:lookup';
  static const _sendOobCodeUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode';
  static const _refreshTokenUrl = 'https://securetoken.googleapis.com/v1/token';

  static const _prefsEmailKey = 'auth_email';
  static const _prefsIdTokenKey = 'auth_id_token';
  static const _prefsUidKey = 'auth_uid';
  static const _prefsRefreshTokenKey = 'auth_refresh_token';
  static const _prefsExpiresAtKey = 'auth_expires_at';

  final http.Client _client;

  String? _email;
  String? _idToken;
  String? _uid;
  String? _refreshToken;
  DateTime? _tokenExpiresAt;

  String? get currentUserEmail => _email;
  String? get currentUserUid => _uid;
  bool get isLoggedIn => _idToken != null;

  /// Restores a previously signed-in session from disk. Called once during
  /// app bootstrap (see `app.dart`), same pattern as
  /// `PreferencesProvider.load()`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_prefsEmailKey);
    _idToken = prefs.getString(_prefsIdTokenKey);
    _uid = prefs.getString(_prefsUidKey);
    _refreshToken = prefs.getString(_prefsRefreshTokenKey);
    final expiresAtRaw = prefs.getString(_prefsExpiresAtKey);
    _tokenExpiresAt = expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw);
    if (_email == null || _idToken == null) {
      _email = null;
      _idToken = null;
      _uid = null;
      _refreshToken = null;
      _tokenExpiresAt = null;
    }
    notifyListeners();
  }

  /// A non-expired ID token for authenticated calls (e.g. Firestore via
  /// [CloudSyncService]), refreshing it first if it's expired or close to
  /// it. Returns `null` if not logged in, or if refreshing fails (e.g. the
  /// device is offline) - callers should treat that as "sync unavailable
  /// right now", not sign the user out.
  Future<String?> getValidIdToken() async {
    if (_idToken == null) return null;
    final expiresSoon = _tokenExpiresAt == null ||
        DateTime.now().isAfter(_tokenExpiresAt!.subtract(const Duration(minutes: 5)));
    if (!expiresSoon) return _idToken;
    if (_refreshToken == null) return _idToken;

    try {
      final response = await _client.post(
        Uri.parse('$_refreshTokenUrl?key=$_apiKey'),
        body: {'grant_type': 'refresh_token', 'refresh_token': _refreshToken!},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return _idToken;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      _idToken = decoded['id_token'] as String;
      _refreshToken = decoded['refresh_token'] as String;
      _tokenExpiresAt =
          DateTime.now().add(Duration(seconds: int.parse(decoded['expires_in'] as String)));
      await _persistSession();
      return _idToken;
    } catch (_) {
      return _idToken;
    }
  }

  Future<AuthAttemptResult> register({
    required String email,
    required String password,
    required AppLanguage language,
  }) async {
    try {
      final signUpResponse = await _post(_signUpUrl, {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      if (signUpResponse case _RestFailure(:final code)) {
        return AuthFailure(authErrorMessage(code, language));
      }
      final idToken = (signUpResponse as _RestSuccess).body['idToken'] as String;

      final verifyResponse = await _post(_sendOobCodeUrl, {
        'requestType': 'VERIFY_EMAIL',
        'idToken': idToken,
      });
      if (verifyResponse case _RestFailure(:final code)) {
        return AuthFailure(authErrorMessage(code, language));
      }
      return const AuthNeedsVerification();
    } catch (error) {
      return AuthFailure('${authErrorMessage('network-error', language)} [$error]');
    }
  }

  Future<AuthAttemptResult> signIn({
    required String email,
    required String password,
    required AppLanguage language,
  }) async {
    try {
      final signInResponse = await _post(_signInUrl, {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      if (signInResponse case _RestFailure(:final code)) {
        return AuthFailure(authErrorMessage(code, language));
      }
      final body = (signInResponse as _RestSuccess).body;
      final idToken = body['idToken'] as String;

      final lookupResponse = await _post(_lookupUrl, {'idToken': idToken});
      if (lookupResponse case _RestFailure(:final code)) {
        return AuthFailure(authErrorMessage(code, language));
      }
      final users = (lookupResponse as _RestSuccess).body['users'] as List;
      final emailVerified = users.isNotEmpty && users.first['emailVerified'] == true;
      if (!emailVerified) {
        return AuthFailure(AppLocalizations(language).t('authErrorEmailNotVerified'));
      }

      _email = body['email'] as String;
      _idToken = idToken;
      _uid = body['localId'] as String;
      _refreshToken = body['refreshToken'] as String;
      _tokenExpiresAt =
          DateTime.now().add(Duration(seconds: int.parse(body['expiresIn'] as String)));
      await _persistSession();
      notifyListeners();
      return const AuthSuccess();
    } catch (error) {
      return AuthFailure('${authErrorMessage('network-error', language)} [$error]');
    }
  }

  Future<void> signOut() async {
    _email = null;
    _idToken = null;
    _uid = null;
    _refreshToken = null;
    _tokenExpiresAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsEmailKey);
    await prefs.remove(_prefsIdTokenKey);
    await prefs.remove(_prefsUidKey);
    await prefs.remove(_prefsRefreshTokenKey);
    await prefs.remove(_prefsExpiresAtKey);
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsEmailKey, _email!);
    await prefs.setString(_prefsIdTokenKey, _idToken!);
    await prefs.setString(_prefsUidKey, _uid!);
    await prefs.setString(_prefsRefreshTokenKey, _refreshToken!);
    await prefs.setString(_prefsExpiresAtKey, _tokenExpiresAt!.toIso8601String());
  }

  Future<_RestResult> _post(String url, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          Uri.parse('$url?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final code = (decoded['error'] as Map<String, dynamic>?)?['message'] as String?;
      // If the response doesn't have the shape we expect, show the raw
      // status+body instead of a made-up placeholder code - that's what
      // actually needs diagnosing when this happens.
      return _RestFailure(code ?? 'HTTP ${response.statusCode}: ${response.body}');
    }
    return _RestSuccess(decoded);
  }
}

sealed class _RestResult {}

class _RestSuccess extends _RestResult {
  _RestSuccess(this.body);
  final Map<String, dynamic> body;
}

class _RestFailure extends _RestResult {
  _RestFailure(this.code);
  final String code;
}
