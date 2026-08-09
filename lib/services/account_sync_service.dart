import 'package:flutter/foundation.dart';

import '../models/price_alert.dart';
import '../models/user_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/price_alerts_provider.dart';
import 'cloud_sync_service.dart';

/// Keeps [PreferencesProvider] and [PriceAlertsProvider] in sync with the
/// signed-in account's Firestore document (`/users/{uid}`), so a user's
/// travel preferences and tracked price alerts follow them to any device
/// they log into - the whole point of having an account, per explicit
/// request, rather than the previous local-only-per-device storage.
///
/// Not a [ChangeNotifier] itself - it has no state the UI reads, just
/// side effects wired up via listeners on the three providers it
/// coordinates. Constructed once in `app.dart` alongside them and disposed
/// with the app.
class AccountSyncService {
  AccountSyncService({
    required AuthProvider auth,
    required PreferencesProvider preferences,
    required PriceAlertsProvider priceAlerts,
    CloudSyncService? cloudSync,
  })  : _auth = auth,
        _preferences = preferences,
        _priceAlerts = priceAlerts,
        _cloudSync = cloudSync ?? CloudSyncService() {
    _wasLoggedIn = _auth.isLoggedIn;
    _auth.addListener(_onAuthChanged);
    _preferences.addListener(_onLocalDataChanged);
    _priceAlerts.addListener(_onLocalDataChanged);
    if (_wasLoggedIn) _pullFromCloud();
  }

  final AuthProvider _auth;
  final PreferencesProvider _preferences;
  final PriceAlertsProvider _priceAlerts;
  final CloudSyncService _cloudSync;

  late bool _wasLoggedIn;

  /// Set while applying data just pulled from the cloud, so that write-back
  /// (`_onLocalDataChanged`) doesn't immediately re-push the same data we
  /// just pulled.
  bool _isApplyingRemote = false;

  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _preferences.removeListener(_onLocalDataChanged);
    _priceAlerts.removeListener(_onLocalDataChanged);
  }

  void _onAuthChanged() {
    final isLoggedIn = _auth.isLoggedIn;
    if (isLoggedIn && !_wasLoggedIn) {
      _wasLoggedIn = true;
      _pullFromCloud();
    } else if (!isLoggedIn) {
      _wasLoggedIn = false;
    }
  }

  void _onLocalDataChanged() {
    if (_isApplyingRemote || !_auth.isLoggedIn) return;
    _pushToCloud();
  }

  Future<void> _pullFromCloud() async {
    final uid = _auth.currentUserUid;
    final idToken = await _auth.getValidIdToken();
    if (uid == null || idToken == null) return;

    try {
      final remote = await _cloudSync.fetchUserDocument(uid: uid, idToken: idToken);
      if (remote == null) {
        // First login from anywhere for this account - seed the cloud with
        // whatever is already on this device instead of leaving it empty.
        await _pushToCloud();
        return;
      }

      _isApplyingRemote = true;
      final remotePreferences = remote['preferences'];
      if (remotePreferences is Map) {
        await _preferences
            .replaceAll(UserPreferences.fromJson(Map<String, dynamic>.from(remotePreferences)));
      }
      final remoteAlerts = remote['priceAlerts'];
      if (remoteAlerts is List) {
        final alerts = <PriceAlert>[];
        for (final entry in remoteAlerts) {
          try {
            alerts.add(PriceAlert.fromJson(Map<String, dynamic>.from(entry as Map)));
          } on FormatException {
            continue;
          }
        }
        await _priceAlerts.replaceAll(alerts);
      }
    } catch (error) {
      // Best-effort: sync failing (offline, Firestore not enabled yet, ...)
      // must never block using the app with local-only data.
      debugPrint('AccountSyncService: pull failed: $error');
    } finally {
      _isApplyingRemote = false;
    }
  }

  Future<void> _pushToCloud() async {
    final uid = _auth.currentUserUid;
    final idToken = await _auth.getValidIdToken();
    if (uid == null || idToken == null) return;

    try {
      await _cloudSync.saveUserDocument(
        uid: uid,
        idToken: idToken,
        data: {
          'preferences': _preferences.preferences.toJson(),
          'priceAlerts': _priceAlerts.alerts.map((a) => a.toJson()).toList(),
        },
      );
    } catch (error) {
      debugPrint('AccountSyncService: push failed: $error');
    }
  }
}
