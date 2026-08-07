import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth_error_messages.dart';
import '../core/localization/app_localizations.dart';

/// Email/password account login via Firebase Authentication (see
/// [DefaultFirebaseOptions] for the project config). Scope is
/// authentication only for now - preferences and price alerts stay
/// local-only (see `todo/login-registrierung.md` for syncing them to the
/// account later).
class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? firebaseAuth}) : _auth = firebaseAuth ?? FirebaseAuth.instance {
    _subscription = _auth.authStateChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Returns null on success, or a message (already localized) to show the
  /// user on failure.
  Future<String?> register({
    required String email,
    required String password,
    required AppLanguage language,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (error) {
      return authErrorMessage(error.code, language);
    } catch (error) {
      return authErrorMessage('unknown', language);
    }
  }

  /// Returns null on success, or a message (already localized) to show the
  /// user on failure.
  Future<String?> signIn({
    required String email,
    required String password,
    required AppLanguage language,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (error) {
      return authErrorMessage(error.code, language);
    } catch (error) {
      return authErrorMessage('unknown', language);
    }
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
