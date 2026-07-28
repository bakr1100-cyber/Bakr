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
/// below. Local notifications (used for the in-app price-alert simulation)
/// work regardless of Firebase.
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
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
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

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
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
  }
}
