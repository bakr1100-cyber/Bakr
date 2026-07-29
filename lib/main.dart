import 'package:flutter/material.dart';

import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NotificationService.init() already fails safe internally (Firebase is
  // optional), but nothing should ever be able to keep the app off-screen -
  // any unexpected startup failure still has to end in runApp().
  try {
    await NotificationService().init();
  } catch (error) {
    debugPrint('NotificationService failed to initialize: $error');
  }
  runApp(const MarocFlyApp());
}
