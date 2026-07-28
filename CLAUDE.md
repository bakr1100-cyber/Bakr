# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

MarocFly AI: a Flutter (iOS/Android) travel app for Moroccans living in
Europe. It's not a plain flight search engine — it's an AI travel advisor
(Darija-first, voice-capable) that finds the cheapest *and smartest* route
to Morocco, including alternate airports, stopovers, and flight+train+bus
combinations, and stays with the traveler from booking through arrival
(the "travel companion" features).

The repo has two independently-versioned parts:

- **`app/`** — the Flutter client.
- **`functions/`** — Firebase Cloud Functions (TypeScript) that back the AI
  orchestrator, flight ranking engine, price tracking, and notifications.

Everything currently runs against **mock implementations** — there are no
real flight/LLM/STT/TTS provider credentials wired up yet. Every external
integration point is an interface with a `Mock*` implementation bound in
one place, so swapping in a real provider never requires touching UI or
business logic. See `docs/INTEGRATIONS.md` for the concrete TODO list per
provider (flight API, ground transport, LLM, voice, push, offline storage,
localization).

## Commands

### Flutter app (`app/`)

Run all of these from `app/`:

```bash
flutter pub get              # install dependencies
flutter analyze              # static analysis — must be clean
flutter test                 # run all widget/unit tests
flutter test test/widget_test.dart --plain-name "search screen"  # run a single test by name
flutter run                  # launch on a connected device/emulator
```

### Cloud Functions (`functions/`)

Run all of these from `functions/`:

```bash
npm install
npm run build                 # tsc compile — must be clean
npm test                      # jest, runs everything in src/__tests__
npx jest rankOptions.test.ts  # run a single test file
npm run lint                  # eslint
npm run serve                 # build + start the functions emulator
```

### Firebase emulator (from repo root)

```bash
npx firebase-tools emulators:start --project demo-marocfly --only functions,firestore
```

Use a `demo-*` project ID (not a real project) to run the emulator without
`firebase login` — this is how it was verified while building this repo.
Note: the `notifyOnPriceDrop` Firestore trigger only registers when the
Firestore emulator is running alongside Functions.

## Architecture

### Client: feature-first, provider-abstracted

`app/lib/` is organized feature-first, not layer-first:

```
lib/
  app/            # MaterialApp.router, go_router config, bottom-nav shell, theme
  core/
    models/       # domain types shared across features (FlightOption, SearchQuery, ChatMessage, ...)
    services/     # FlightProvider, LlmClient, SttClient/TtsClient interfaces + Mock* impls
    offline/      # OfflineCache interface + in-memory impl (Drift-backed impl is a TODO)
    providers.dart# the ONE place service interfaces are bound to implementations (swap here)
  features/
    flight_search/   # origin/dest/date/pax form -> ranked results (Riverpod Notifier + go_router)
    ai_assistant/     # chat UI over LlmClient
    voice/            # mic button + STT/TTS controller, used inside ai_assistant
    travel_companion/ # pre-flight/at-airport/in-flight/post-landing timeline
    price_alerts/     # watchlist UI (in-memory state; Firestore-backed persistence is a TODO)
```

Each feature follows `application/` (Riverpod `Notifier` controllers) +
`presentation/` (screens/widgets). Controllers never call external APIs
directly — they go through the interfaces in `core/services/` via
`core/providers.dart`, so a feature doesn't know or care whether it's
talking to a mock or a real backend.

**State management is Riverpod 3's `Notifier`/`NotifierProvider`**, not the
legacy `StateNotifierProvider` — riverpod 3.x still ships the legacy API
but it lives under a `legacy/` module internally; new controllers should
follow the existing `Notifier` pattern (see
`flight_search/application/flight_search_controller.dart`).

Navigation is a single `go_router` `ShellRoute` with 4 bottom-nav
destinations (`/search`, `/assistant`, `/companion`, `/alerts`). Flight
search is the initial route so it's reachable with zero taps, matching the
product requirement of "max 3 clicks to flight search". Each screen owns
its own `Scaffold`/`AppBar`; `MainShell` only supplies the
`NavigationBar`.

Theme (`app/lib/app/theme/`) is built from the Moroccan flag palette
(`AppColors.moroccanRed` / `moroccanGreen` / `moroccanWhite`) via
`ColorScheme.fromSeed`, with large touch targets (56dp buttons) baked into
the theme rather than per-widget, per the "very large buttons, very simple
UI" requirement. Both light and dark themes exist; `themeMode` follows the
system setting.

### Functions: pure logic separated from Firebase runtime

`functions/src/` mirrors the client's "interface + mock, swap in one
place" pattern:

```
functions/src/
  shared/types.ts          # FlightOption, SearchQuery, TransportLeg, PricePoint — the wire format between client and functions
  shared/llmClient.ts      # LlmClient interface + MockLlmClient (keyword-based Darija/DE/FR intent extraction)
  flightEngine/
    providers.ts           # FlightProvider + GroundTransportProvider interfaces + mocks
    rankOptions.ts          # searchAndRankOptions() — combines provider results, filters by budget, sorts by price
  orchestrator/orchestrate.ts  # ties LlmClient + FlightProvider together; the aiOrchestrator function's actual logic
  priceTracking/predictTrend.ts # "book now / wait" heuristic from price history
  notifications/priceAlertRule.ts # shouldNotify() — pure trigger predicate
  index.ts                 # thin firebase-functions v2 wrappers (onCall/onSchedule/onDocumentUpdated) around the above
```

The important convention: **business logic (`orchestrate`, `rankOptions`,
`predictTrend`, `shouldNotify`) is written as plain TypeScript functions
that take their dependencies as parameters and know nothing about
`firebase-functions` or `firebase-admin`.** `index.ts` is the only file
that imports the Functions SDK and wires HTTP/schedule/Firestore triggers
around that logic. This is why `npm test` runs without an emulator —
keep new business logic in this style so it stays unit-testable.

### End-to-end data flow (flight search via chat)

1. User types or speaks free text ("Bghit arkhass vol mn Düsseldorf l
   Nador").
2. Client calls the `aiOrchestrator` callable function.
3. `orchestrate()` calls `LlmClient.extractIntent` — if origin/destination
   can't be determined, it returns a clarifying question instead of
   guessing (this is a deliberate product requirement: the AI must never
   confirm false information).
4. Once a `SearchQuery` is resolved, `searchAndRankOptions()` calls the
   `FlightProvider` for direct/alternate-airport/stopover options, filters
   by `maxBudget` if set, and sorts by price.
5. `LlmClient.explainResults` turns the ranked options into a natural-
   language reply.
6. The plain (non-chat) search form skips steps 2–3 and calls
   `searchFlights` directly with an already-structured `SearchQuery`.

### Firestore shape (`firestore.rules`)

User-owned data lives under `users/{userId}/...` (searches, conversations,
travelPreferences); `priceAlerts` is a top-level collection with a
`userId` field on each doc. `priceHistory` and `travelKnowledge` are
read-only to clients and written only by Cloud Functions (rules deny
client writes outright). Match this shape when wiring real Firestore
reads/writes — or update the rules deliberately if the schema changes.

## Conventions worth knowing

- **No dependency injection framework** — `core/providers.dart` (client)
  and constructor parameters (functions) are the only two places
  implementations get bound. Don't reach for `get_it` or similar; this
  scale of app doesn't need it.
- **Currency/price values are plain `double`/`number`**, not a Money type —
  don't introduce one without a reason tied to a real requirement (e.g.
  multi-currency support isn't in scope yet).
- Mock services intentionally return data that matches the scenarios
  described in the original product brief (e.g. Düsseldorf→Fès direct at
  320€ vs. a Rabat+train combo at 190€) so the UI/API demo the "smart
  routing" pitch even without a real flight API. Keep new mock data
  internally consistent with existing mocks if you touch them.
- `functions/tsconfig.json` excludes `src/__tests__` from the `tsc` build
  (tests run through `ts-jest`, not the compiled `lib/` output) — don't
  "fix" this by including tests in the build.
