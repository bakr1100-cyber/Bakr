# Real "outside the app" push notifications for price drops

## Done
Built the full pipeline the original note called for:

1. **Client captures a push token.** `NotificationService.init()` now
   calls `FirebaseMessaging.instance.getToken(vapidKey: ...)` after
   permission is granted; `main.dart` passes the initialized service into
   `MarocFlyApp` instead of discarding it. `AccountSyncService.
   setPushToken()` pushes that token to the signed-in account's Firestore
   document (`users/{uid}.pushToken`) - deferred until login if the token
   arrives first. `CloudSyncService.saveUserDocument` was fixed to use a
   real Firestore `updateMask` (previously any partial save silently
   wiped out every other field on the document - harmless until now,
   since `pushToken` is the first field synced independently of
   preferences/priceAlerts).
2. **Server checks prices on a schedule, not just on app-open.**
   `cloudflare-worker/src/price_check_job.js`, fired by a Cron Trigger
   (`wrangler.toml`, every 15 minutes) - reads every user with a push token
   and tracked alerts from Firestore (Admin-scoped, via a service-account
   OAuth2 token minted in `google_auth.js`), re-quotes each route via
   Duffel, and sends a real Firebase Cloud Messaging push on a meaningful
   drop (same €15/5% bar as the in-app "alternatives" logic). Updates the
   stored alert's `currentPriceEur` too, so the app reflects the same drop
   next time it's opened.
3. **iPad/Safari can only receive these as an installed PWA.** Added a
   dismissible in-app hint (Price Alerts screen) nudging the user to "Add
   to Home Screen" when running as a normal browser tab - a page open in
   plain Safari can't receive push notifications at all, no matter how
   well the rest of this works.
4. `web/firebase-messaging-sw.js` added (required for FCM to deliver to a
   background/closed tab at all - without it, only foreground delivery
   works).

Verified: `flutter analyze` clean, full `flutter test` suite passing
(including new tests for the updateMask fix and push-token sync timing),
and the RS256 service-account JWT signing in `google_auth.js` independently
verified correct (structurally and cryptographically) via a throwaway
Node script using a generated keypair - see the session this was built in
for that script, not committed (nothing to verify against without a real
service account).

## Still needed: two credentials only reachable via your own Google/Firebase account access
Same situation as the Duffel API key earlier - the code is complete and
will "just work" once these are set, but I can't generate or fetch them
myself:

1. **`FIREBASE_VAPID_KEY`** - Firebase console → Project settings → Cloud
   Messaging → Web configuration → "Web Push certificates" → generate a
   key pair → copy the "Key pair" value. Set it as a local env var named
   `FIREBASE_VAPID_KEY` before running `scripts/deploy_gh_pages.sh` (or
   export it permanently in your shell profile) - the script already
   passes it through as a `--dart-define` if present.
2. **A Firebase/Google Cloud service account**, for the scheduled job to
   read Firestore and send pushes: Google Cloud Console → IAM & Admin →
   Service Accounts → create one (or reuse an existing one) with the
   "Cloud Datastore User" role → Keys → Add key → JSON → download it.
   From that JSON file:
   - `client_email` → GitHub repo secret `FIREBASE_SERVICE_ACCOUNT_EMAIL`
   - `private_key` → GitHub repo secret `FIREBASE_SERVICE_ACCOUNT_KEY`
     (paste the whole PEM value, including the BEGIN/END lines)

   Same place as the `DUFFEL_API_KEY` secret:
   `github.com/bakr1100-cyber/Bakr/settings/secrets/actions`. The next
   push to `cloudflare-worker/**` (or a manual workflow run) picks these
   up automatically - the deploy workflow already pushes them
   unconditionally, same as the Mistral key.

Once both are set, the whole pipeline activates with no further code
changes - price alerts should start arriving as real notifications on the
schedule above, even with the app fully closed, for anyone who's added
Tayarti to their Home Screen.
