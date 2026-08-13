import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Set via `flutter run --dart-define=FIREBASE_VAPID_KEY=...` - get this
/// from the Firebase console: Project settings -> Cloud Messaging -> Web
/// configuration -> "Web Push certificates" -> generate a key pair, copy
/// the "Key pair" value. This is what lets a *web* app (not just native
/// iOS/Android) request an FCM registration token - `getToken()` below
/// fails without it, same graceful-degradation pattern as every other
/// optional integration in this app (Duffel, Mistral, ...): push
/// notifications just silently stay unavailable, nothing else breaks.
const _vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

/// Push notifications for price alerts and travel-companion updates
/// (gate changes, boarding calls, delays), and the one place that actually
/// calls `Firebase.initializeApp()` - [AuthProvider] depends on that having
/// already happened (awaited in `main()` before `runApp()`) since
/// `FirebaseAuth.instance` needs a default Firebase app to exist.
///
/// [init] fails safe (catches and logs) so the rest of the app keeps
/// working even if Firebase is unreachable (blocked network, ad blocker) -
/// but note that failure here would also silently break login, not just
/// push notifications.
///
/// Local notifications (used for the in-app price-alert simulation) work on
/// Android/iOS regardless of Firebase - but NOT on web: the pinned
/// `flutter_local_notifications` version (17.2.4) has no web platform
/// implementation at all (web support landed in a later major version), so
/// [showLocalNotification] is a guaranteed no-op on the deployed web build.
/// [showLocalNotification] returns whether it could actually show anything,
/// so callers on web can fall back to an in-app confirmation instead of
/// silently assuming the user saw something.
class NotificationService {
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _firebaseReady = false;
  String? _pushToken;

  Future<void> init() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    try {
      // A hard timeout is essential here, not just a try/catch: if Firebase's
      // JS SDK fails to load from its CDN (blocked network, ad blocker,
      // corporate proxy), the underlying JS interop promise can hang forever
      // without ever rejecting back to Dart - which would leave the whole
      // app stuck on a blank white screen before `runApp()` ever runs.
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 5));
      final settings = await FirebaseMessaging.instance
          .requestPermission()
          .timeout(const Duration(seconds: 5));
      _firebaseReady = true;
      if (settings.authorizationStatus == AuthorizationStatus.authorized && _vapidKey.isNotEmpty) {
        // Failure here (no VAPID key configured yet, browser doesn't
        // support the Push API - notably plain Safari tabs that haven't
        // been added to the Home Screen) must not affect the rest of
        // Firebase/push setup, which already succeeded above.
        try {
          _pushToken = await FirebaseMessaging.instance
              .getToken(vapidKey: _vapidKey)
              .timeout(const Duration(seconds: 8));
        } catch (error) {
          debugPrint('NotificationService: could not get a push token ($error).');
        }
      }
    } catch (error) {
      _firebaseReady = false;
      debugPrint(
        'NotificationService: Firebase not configured for this build, '
        'push notifications disabled ($error).',
      );
    }
  }

  bool get isPushEnabled => _firebaseReady;

  /// This device's FCM registration token, if push notifications are fully
  /// set up (permission granted, VAPID key configured, browser supports
  /// it) - `null` otherwise. [AccountSyncService.setPushToken] pushes this
  /// to the signed-in account's Firestore document so the server-side
  /// price-check job knows where to deliver that account's notifications.
  String? get pushToken => _pushToken;

  /// Returns true if a real local notification could be shown, false if the
  /// current platform can't show one (currently: web, see class doc).
  Future<bool> showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return false;
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'marocfly_alerts',
          'MarocFly Benachrichtigungen',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return true;
  }
}
