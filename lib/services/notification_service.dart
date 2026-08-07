import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Push notifications for price alerts and travel-companion updates
/// (gate changes, boarding calls, delays).
///
/// IMPORTANT: this build has no real Firebase project wired up - there is
/// no `firebase_options.dart` generated for this repository. [init] fails
/// safe (catches and logs) so the rest of the app keeps working without
/// push; to enable real push notifications, run `flutterfire configure`
/// against a real Firebase project and pass the generated
/// `DefaultFirebaseOptions.currentPlatform` into `Firebase.initializeApp`
/// below.
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
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      await FirebaseMessaging.instance
          .requestPermission()
          .timeout(const Duration(seconds: 5));
      _firebaseReady = true;
    } catch (error) {
      _firebaseReady = false;
      debugPrint(
        'NotificationService: Firebase not configured for this build, '
        'push notifications disabled ($error).',
      );
    }
  }

  bool get isPushEnabled => _firebaseReady;

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
