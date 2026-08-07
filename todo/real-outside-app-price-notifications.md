# Real "outside the app" push notifications for price drops

The SnackBar fix (see recent commit) only shows the price-check result while
the user is actively looking at the Price Alerts screen. The user explicitly
does NOT consider that a good enough solution and wants the real thing: a
notification that arrives even when the app is closed (like a normal phone
notification on the lock screen), the way it was originally supposed to
work.

To actually do this:
1. Upgrade `flutter_local_notifications` past 17.2.4 to a version with real
   web support, and wire up `WebFlutterLocalNotificationsPlugin
   .requestNotificationsPermission()` (must be called synchronously inside
   a user gesture, e.g. right when the user taps "watch this price").
2. On iPad, Safari only supports web notifications for a page added to the
   Home Screen ("Add to Home Screen") - a page open in a normal Safari tab
   cannot receive them at all. So this also needs either:
   - clear in-app guidance telling the user to add MarocFly to their Home
     Screen for notifications to work, and/or
   - a proper native app build (not just the web deployment) if arriving
     notifications should work without that step.
3. `checkForDrops()` is currently only triggered by the user manually
   tapping refresh - for a notification to arrive "on its own" without the
   app open, the price check itself needs to run server-side on a schedule
   (see the existing comment in `price_alerts_provider.dart`: "wire
   checkForDrops to a scheduled backend job... polling the real flight API")
   and push to the client, rather than running client-side only.

Deferred - user said "we'll do it later," not now.
