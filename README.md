# MarocFly AI

The intelligent travel advisor for the Moroccan diaspora in Europe. Not the
cheapest flight — the smartest way home: flights, trains (ICE/TGV/ONCF) and
buses combined, explained in plain language, in Darija, Arabic, German,
French or English.

## What's in this build

This repository contains a working **Flutter application foundation** that
implements the actual product flows from the spec end to end, with the
external integrations (flight/rail data, LLM, cloud speech, Firebase project)
mocked behind clean interfaces so the UI, state management and business
logic can be built, tested and demoed today. It is a solid starting point,
**not** a store-ready production build — see "What's mocked" below before
promising this to users.

### Implemented

- **Design**: Morocco-flag palette (red/green/white), light + dark themes,
  large tap targets, fast (160-240 ms) animations. See `lib/core/theme/`.
- **3-tap search**: origin → destination → search. See
  `lib/screens/search/search_form_screen.dart`.
- **Smart Flight Engine** (`lib/services/flight_search_service.dart`):
  generates and explains direct flights, alternative departure airports,
  alternative Moroccan hub + onward ONCF train, stopovers via Madrid/
  Barcelona/Paris/Lissabon/Casablanca, and flight+train multimodal routes
  (e.g. ICE → Frankfurt → flight → Rabat → ONCF → Fès), and only ever
  surfaces an alternative when it's genuinely cheaper than the direct
  route. Budget mode filters/relaxes results to the user's stated maximum.
  Each individual flight leg is priced through a swappable
  `FlightPriceSource` - synthetic mock data by default, or **real Amadeus
  quotes** when Amadeus sandbox credentials are configured (see "Real
  flight data" below). Train/bus legs (ICE, ONCF) are always synthetic -
  there is no rail API integrated.
- **Conversational AI advisor** (`lib/services/nlu_service.dart`,
  `ai_assistant_service.dart`): understands free text/voice in Darija
  (Arabic script and Arabizi/Latin), Modern Standard Arabic, German, French
  and English — city names, dates ("nächste Woche"), budget ("200 €"),
  family travel, and "no long layover" — merges it across turns, asks
  clarifying questions when something is missing or uncertain ("Ich bin mir
  nicht ganz sicher. Meintest du Düsseldorf nach Fès?"), and never
  confirms information it isn't confident about.
- **Voice assistant**: on-device speech-to-text and text-to-speech
  (`lib/services/voice_service.dart`), male/female voice toggle, wired into
  the chat screen's mic button.
- **Travel companion** (`lib/services/travel_companion_service.dart`):
  before-trip (check-in, baggage, weather), at-airport (gate, boarding),
  during-flight (offline-capable travel Q&A copy), and after-landing
  (onward ONCF connection) timeline for a booked itinerary.
- **Price alerts & prediction**: local-notification price-drop alerts and a
  simple book-now-vs-wait heuristic (`price_prediction_service.dart`).
- **Personal recommendations**: locally persisted preferences (favorite
  airports/airlines, usual budget, solo vs. family) shown in the profile
  screen and used to seed future search/chat defaults.
- **Language & theme**: Darija/Arabic/German/French/English UI switcher
  (`lib/core/localization/`) with RTL support, system/light/dark theme
  toggle.
- Unit tests for the NLU parser and the flight/multimodal search engine
  (`test/`).

### What's mocked and needs real integration before shipping

| Area | This build | To go to production |
|---|---|---|
| Flight prices & schedules | Real quotes via **Amadeus for Developers** when `AMADEUS_CLIENT_ID`/`AMADEUS_CLIENT_SECRET` are set (sandbox environment - real but limited/cached data), else deterministic synthetic data | Go through Amadeus's production-access review, or add another `FlightPriceSource` for a different aggregator |
| Train/bus prices & schedules | Always synthetic fixed prices (ONCF ~18 €, ICE ~35 €) - Amadeus has no rail data | Add an ONCF/rail timetable API behind a similar interface |
| Natural language understanding | Rule-based keyword/regex parser (`NluService`) | A multilingual LLM fine-tuned/prompted for Darija, ideally with RAG over live fare data |
| Speech | On-device OS speech engines (`speech_to_text`, `flutter_tts`) | Cloud STT/TTS (e.g. Whisper-family STT, ElevenLabs TTS) for much better Darija quality |
| Push notifications | `NotificationService` fails safe with no Firebase project configured | Run `flutterfire configure` against a real Firebase project, wire `DefaultFirebaseOptions` into `main.dart` |
| Personal recommendations | Local `shared_preferences` only | Sync to Firestore per user account so it follows the user across devices |
| iOS/Android platform projects | Not present in this repo (no Flutter SDK available in this environment to run `flutter create`) | See setup below |

The code has been written and manually reviewed for correctness but **has
not been compiled or run** — this environment has no Flutter/Dart SDK
installed. Run `flutter analyze` and `flutter test` locally before relying
on it.

## Setup (on a machine with the Flutter SDK installed)

This repo currently holds the Dart application (`lib/`, `pubspec.yaml`,
`test/`) but not the generated native platform projects. To get a runnable
app:

```bash
# 1. Generate the iOS/Android/etc. platform scaffolding into this repo
flutter create --project-name marocfly_ai --org com.marocfly .

# 2. Install dependencies
flutter pub get

# 3. (Optional but needed for push notifications) wire up a real Firebase project
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Static analysis and tests
flutter analyze
flutter test

# 5. Run it
flutter run
```

`flutter create .` will not overwrite `lib/main.dart` or `pubspec.yaml` if
you answer its prompts carefully, but review the diff afterwards - it may
add its own `pubspec.yaml` scaffolding that needs merging with the one in
this repo.

## Real flight data (Amadeus for Developers)

By default the app runs on synthetic flight data (`MockFlightPriceSource`)
so it works fully offline with no setup. To see real quotes:

1. Sign up for free at <https://developers.amadeus.com>, create an app in
   your dashboard, and copy its **Test environment** API Key and API
   Secret - self-serve, no partner agreement or approval needed, unlike
   Skyscanner. The sandbox also gives you a Test Data management tool to
   shape what the API returns, which is why this build uses Amadeus
   instead of Duffel.
2. Run the app with them as compile-time defines:

   ```bash
   flutter run \
     --dart-define=AMADEUS_CLIENT_ID=your_api_key \
     --dart-define=AMADEUS_CLIENT_SECRET=your_api_secret
   ```

   Never commit real credentials to the repo; pass them at build/run time
   only (or via your CI secret store for release builds).
3. That's it - `app.dart` picks up both defines and switches
   `FlightSearchService` from `MockFlightPriceSource` to
   `AmadeusFlightPriceSource`, which falls back to mock data automatically
   if a request errors or a route has no offers, so bad/missing
   credentials never break the app.

Notes/limitations of the Amadeus integration as implemented:

- Amadeus's **test environment** returns real (not fictional) flight data,
  but from a limited/cached data set - coverage of smaller regional
  airports (Nador, Oujda) is patchy, so those routes will often silently
  fall back to mock data. Going to full production pricing/coverage
  requires Amadeus's paid production-access process.
- Only flight legs go through Amadeus; ICE/ONCF train legs stay synthetic
  fixed prices (`lib/services/flight_search_service.dart`).
- The client requests `currencyCode=EUR` explicitly on every search, so
  amounts should be in EUR for supported markets; verify this holds for
  the specific routes you care about before trusting it blindly.
- OAuth2 access tokens are fetched via client-credentials and cached in
  memory until shortly before they expire (see `_accessTokenOrFetch` in
  `lib/services/amadeus_flight_api.dart`).
- See `lib/services/amadeus_flight_api.dart` for the raw API client and
  `lib/services/amadeus_flight_price_source.dart` for the adapter/fallback
  logic.

## Architecture

```
lib/
  core/           theme, localization, shared constants
  models/         Airport, TripLeg, Itinerary, TravelIntent, ChatMessage, ...
  services/       FlightSearchService (+ FlightPriceSource: Mock/Amadeus),
                  NluService, AiAssistantService, VoiceService,
                  NotificationService, TravelCompanionService,
                  PricePredictionService, UserPreferencesService
  providers/      ChangeNotifier state for chat, search, locale, theme,
                  preferences, price alerts
  screens/        onboarding, home (bottom nav), search, assistant,
                  companion, alerts, profile, settings
  widgets/        shared UI (big buttons, airport picker, chat bubble, ...)
```

State management is `provider`; screens are grouped in a bottom-navigation
shell (`lib/screens/home/home_screen.dart`) with five tabs: Search,
Advisor (chat), Companion, Alerts, Settings.

## Roadmap to a store-ready app

1. Generate and configure the native Android/iOS projects (above) and a real
   Firebase project (Auth, Firestore, Cloud Messaging).
2. Go through Amadeus's production-access review (or add another
   `FlightPriceSource`) for real production flight prices, and add an
   ONCF/rail timetable API behind a similar interface for real train
   pricing.
3. Replace `NluService`/`AiAssistantService` with a hosted multilingual LLM
   (with strong Darija support) behind the same `TravelIntent`/
   `AssistantTurn` contracts, grounded with RAG over live fare/schedule data.
4. Add authentication and per-user cloud sync for preferences and bookings.
5. Add real payment/booking integration.
6. App Store / Play Store assets, privacy policy, and store listings in the
   target languages.
