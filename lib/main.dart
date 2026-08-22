import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Without this, `DateFormat.yMMMMd(<any locale but the intl default>)`
  // throws a LocaleDataException at first use rather than silently
  // formatting in the wrong language - every locale-aware DateFormat call
  // needs this to have run first, so it happens once, up front, for all
  // locales (passing no argument loads every locale's data, not just one).
  try {
    await initializeDateFormatting();
  } catch (error) {
    debugPrint('initializeDateFormatting failed: $error');
  }
  // NotificationService.init() already fails safe internally (Firebase is
  // optional), but nothing should ever be able to keep the app off-screen -
  // any unexpected startup failure still has to end in runApp(). The
  // instance is passed into MarocFlyApp (rather than discarded) so its
  // Firebase setup and FCM push token aren't wasted/redone.
  final notificationService = NotificationService();
  try {
    // The timeout is the important part, not the catch. Firebase's setup
    // reaches the network, and on a connection that neither succeeds nor
    // fails - a captive portal, a blocked network, a stalled mobile
    // connection - the future simply never completes. Awaiting it bare
    // leaves the user staring at a blank screen indefinitely, which is a
    // far worse outcome than starting without push notifications.
    await notificationService.init().timeout(const Duration(seconds: 5));
  } catch (error) {
    debugPrint('NotificationService failed to initialize: $error');
  }
  runApp(MarocFlyApp(notificationService: notificationService));
}
