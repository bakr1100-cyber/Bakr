import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth_error_messages.dart';
import '../core/localization/app_localizations.dart';

/// Outcome of [AuthProvider.register] or [AuthProvider.signIn]. A plain
/// `String?` (null = success) doesn't leave room for the third case that
/// [register] needs: it succeeded, but the account isn't usable yet until
/// the verification email is confirmed.
sealed class AuthAttemptResult {
  const AuthAttemptResult();
}

/// Signed in successfully - [AuthProvider.currentUser] is now set.
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

/// Email/password account login via Firebase Authentication (see
/// [DefaultFirebaseOptions] for the project config). Scope is
/// authentication only for now - preferences and price alerts stay
/// local-only (see `todo/login-registrierung.md` for syncing them to the
/// account later).
///
/// Registration requires email verification before the account can log in
/// (the standard SaaS pattern: register -> verification email -> click link
/// -> log in) - [register] always signs the user back out immediately after
/// creating the account, specifically so a freshly registered, unverified
/// account is never treated as "logged in".
class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? firebaseAuth}) : _auth = firebaseAuth ?? FirebaseAuth.instance {
    _subscription = _auth.authStateChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthAttemptResult> register({
    required String email,
    required String password,
    required AppLanguage language,
  }) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.sendEmailVerification();
      await _auth.signOut();
      return const AuthNeedsVerification();
    } on FirebaseAuthException catch (error) {
      // TEMP DEBUG: append the raw code so the actual cause is visible on
      // screen instead of always collapsing to the generic message -
      // remove once the real error is diagnosed.
      return AuthFailure('${authErrorMessage(error.code, language)} [${error.code}]');
    } catch (error) {
      return AuthFailure('${authErrorMessage('unknown', language)} [$error]');
    }
  }

  Future<AuthAttemptResult> signIn({
    required String email,
    required String password,
    required AppLanguage language,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        // Don't leave an unverified account signed in just because the
        // password was correct - re-fetch first, Firebase's emailVerified
        // flag on the cached user can be stale right after verifying.
        await user.reload();
        if (!_auth.currentUser!.emailVerified) {
          await _auth.signOut();
          return AuthFailure(AppLocalizations(language).t('authErrorEmailNotVerified'));
        }
      }
      return const AuthSuccess();
    } on FirebaseAuthException catch (error) {
      // TEMP DEBUG: see the register() method for why.
      return AuthFailure('${authErrorMessage(error.code, language)} [${error.code}]');
    } catch (error) {
      return AuthFailure('${authErrorMessage('unknown', language)} [$error]');
    }
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
