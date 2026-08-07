# TODO

Deferred items - not urgent, revisit later.

- **Price-alert notifications don't actually reach the user on web.**
  `checkForDrops()` in `lib/providers/price_alerts_provider.dart` calls
  `NotificationService.showLocalNotification()` on a simulated price drop,
  but `lib/services/notification_service.dart` never requests browser
  notification permission on web (`flutter_local_notifications` requires
  calling `WebFlutterLocalNotificationsPlugin.requestNotificationsPermission()`
  synchronously inside a user gesture before `.show()` will work - see
  https://pub.dev/packages/flutter_local_notifications). Even with that
  fixed, Safari on iPad only supports web notifications for a page added to
  the Home Screen ("Add to Home Screen"), not a page open in a regular
  Safari tab. Two possible fixes, not yet decided which:
  1. Add the missing web permission request (works only once installed to
     Home Screen on iPad Safari).
  2. Also/instead show the price change directly in-app (e.g. a badge on
     the Price Alerts screen) so it's visible regardless of notification
     permission or install state.

- **Voice STT/TTS quality on Safari.** Proposed but not built: migrate
  voice input/output from Safari's native Web Speech API to Cloudflare
  Workers AI's Whisper (STT) + MeloTTS (TTS) via new `/ai/stt` and `/ai/tts`
  Worker routes. Would likely fix STT accuracy issues (e.g. picking up the
  word "Erlauben" from the permission dialog, garbled Darija transcripts)
  and reduce reliance on manually pressing send. Not started - real effort,
  and Safari's `MediaRecorder` support for raw audio capture is itself
  sometimes flaky, so it isn't guaranteed to fully fix everything either.
