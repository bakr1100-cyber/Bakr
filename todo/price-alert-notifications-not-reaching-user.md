# Price-alert notifications don't actually reach the user on web

`checkForDrops()` in `lib/providers/price_alerts_provider.dart` calls
`NotificationService.showLocalNotification()` on a simulated price drop, but
`lib/services/notification_service.dart` never requests browser notification
permission on web (`flutter_local_notifications` requires calling
`WebFlutterLocalNotificationsPlugin.requestNotificationsPermission()`
synchronously inside a user gesture before `.show()` will work - see
https://pub.dev/packages/flutter_local_notifications).

Even with that fixed, Safari on iPad only supports web notifications for a
page added to the Home Screen ("Add to Home Screen"), not a page open in a
regular Safari tab.

Two possible fixes, not yet decided which:
1. Add the missing web permission request (works only once installed to
   Home Screen on iPad Safari).
2. Also/instead show the price change directly in-app (e.g. a badge on the
   Price Alerts screen) so it's visible regardless of notification
   permission or install state.
