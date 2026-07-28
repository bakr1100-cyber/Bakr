# Integrations TODO

Everything in this repo currently runs against mock implementations so the
app and functions work end-to-end with zero external credentials. This is
the checklist for swapping each mock for the real thing.

## 1. Firebase project

- Create a Firebase project, then run `flutterfire configure` from `app/`
  to generate `firebase_options.dart` and register the iOS/Android apps.
- Replace the placeholder project ID in `.firebaserc`.
- Add `firebase_core`, `cloud_firestore`, `firebase_auth`,
  `firebase_messaging`, and a real HTTPS-callable client (`cloud_functions`)
  to `app/pubspec.yaml`, and initialize `Firebase.initializeApp()` in
  `app/lib/main.dart`.
- `firestore.rules` already assumes `request.auth.uid`-scoped documents
  under `users/{userId}/...` plus a top-level `priceAlerts` collection with
  a `userId` field — wire real writes to match that shape, or adjust the
  rules if the schema changes.

## 2. Flight data

- Pick a provider (Duffel, Kiwi Tequila, Amadeus Self-Service are the usual
  candidates for this kind of aggregation).
- Implement `FlightProvider` in `functions/src/flightEngine/providers.ts`
  against the real API, replacing `MockFlightProvider`. The interface
  (`searchDirect` / `searchAlternateAirports` / `searchStopovers`) and the
  ranking logic in `rankOptions.ts` don't need to change.
- Store the API key as a Firebase Functions secret
  (`firebase functions:secrets:set`), never in source.

## 3. Ground transport (train/bus)

- Deutsche Bahn and SNCF have official/semi-official APIs.
- **ONCF (Morocco's rail operator) has no known public API.** Realistically
  this starts as a maintained static timetable dataset (JSON checked into
  `functions/src/flightEngine/` or a Firestore collection) rather than a
  live integration. Flag this explicitly to whoever picks up the work.
- Implement `GroundTransportProvider` in `providers.ts` once a data source
  is chosen.

## 4. LLM (AI advisor)

- Get an Anthropic API key and call it from
  `functions/src/shared/llmClient.ts`, replacing `MockLlmClient`.
- `extractIntent` should become a Claude tool-use call with a `SearchQuery`
  extraction tool; `explainResults` becomes a normal completion call that
  receives the ranked `FlightOption[]` as context.
- Darija (Arabic script + Arabizi) has no dedicated locale/tooling — handle
  it via system-prompt instructions and a handful of few-shot examples
  rather than trying to formally localize it. Test with native speakers
  before shipping; a mishandled Darija reply is worse than admitting
  uncertainty (see the "never confirm false information" rule in
  `orchestrate.ts`).
- Store the key as a Functions secret, same as the flight API key.

## 5. Voice (STT/TTS)

- On-device speech engines don't reliably support Darija, so plan on a
  cloud provider (Azure Speech and Google Cloud Speech both support Arabic;
  neither has first-class Darija support, so expect to prompt/post-process
  around that gap).
- Implement `SttClient`/`TtsClient` in `app/lib/core/services/voice_clients.dart`
  against the chosen provider's Flutter plugin or a callable-function proxy.
- The product spec calls for both a male and female voice
  (`VoiceGender` is already modeled in `voice_clients.dart`).

## 6. Push notifications

- `notifyOnPriceDrop` in `functions/src/index.ts` currently only logs when
  `shouldNotify` returns true. Wire it to
  `admin.messaging().send(...)` once FCM tokens are stored per user
  (e.g. `users/{userId}.fcmToken`).
- `snapshotPrices` is a no-op stub; once a real `FlightProvider` exists,
  have it read watched routes (from `priceAlerts`) and write `PricePoint`
  docs to `priceHistory`, which `predictTrend` already knows how to read.

## 7. Offline persistence

- `app/lib/core/offline/offline_cache.dart` is in-memory only. Swap
  `InMemoryOfflineCache` for a `drift`-backed (SQLite) implementation so
  cached search results and static travel info survive app restarts.

## 8. Localization

- UI strings are currently hardcoded in German only, matching the primary
  target market. Proper ARB-based localization for DE/FR/EN/MSA (Darija is
  handled by the LLM layer, not app-chrome localization — see §4) is
  follow-up work: add `flutter_localizations` + `intl` codegen
  (`l10n.yaml`, `lib/l10n/app_*.arb`) and replace hardcoded strings with
  `AppLocalizations.of(context)`.
