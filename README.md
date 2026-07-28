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
- **Monetization: affiliate booking commissions** (`lib/services/affiliate_service.dart`):
  the app has no payment processing or booking backend of its own, so each
  flight leg's "book" button opens a commission-tracked outbound link to a
  travel-affiliate network (self-serve, Travelpayouts-style - see
  "Booking commissions" below) instead of a fake in-app checkout. Train
  legs (ONCF/ICE) link to the operator's own site with no commission,
  since no rail affiliate program is wired up.
- Unit tests for the NLU parser, the flight/multimodal search engine, and
  the affiliate link builder (`test/`).

### What's mocked and needs real integration before shipping

| Area | This build | To go to production |
|---|---|---|
| Flight prices & schedules | Deterministic synthetic data (`MockFlightPriceSource`). `AmadeusFlightPriceSource` exists and is wired up, but **Amadeus's self-service developer portal was decommissioned on July 17, 2026** - new self-serve credentials are no longer obtainable, only Enterprise (contracted) access still works | Add a currently-self-serve source (e.g. Duffel) behind `FlightPriceSource`, or use Amadeus Enterprise if you have that relationship |
| Train/bus prices & schedules | Always synthetic fixed prices (ONCF ~18 €, ICE ~35 €) - Amadeus has no rail data | Add an ONCF/rail timetable API behind a similar interface |
| Natural language understanding | Rule-based keyword/regex parser (`NluService`) | A multilingual LLM fine-tuned/prompted for Darija, ideally with RAG over live fare data |
| Speech | On-device OS speech engines (`speech_to_text`, `flutter_tts`) | Cloud STT/TTS (e.g. Whisper-family STT, ElevenLabs TTS) for much better Darija quality |
| Push notifications | `NotificationService` fails safe with no Firebase project configured | Run `flutterfire configure` against a real Firebase project, wire `DefaultFirebaseOptions` into `main.dart` |
| Personal recommendations | Local `shared_preferences` only | Sync to Firestore per user account so it follows the user across devices |
| iOS platform project | Not present (needs Xcode/macOS to generate - unavailable in this build environment) | Run `flutter create --platforms=ios .` on a Mac |
| Booking commissions | Real, working outbound links via `AffiliateService`, but earn nothing until you set a real `AFFILIATE_MARKER` (no fake placeholder revenue) | Join a flight affiliate program (e.g. via Travelpayouts) and configure the marker - see "Booking commissions" below |

**Verified against a real Flutter SDK** (Flutter 3.44.8): `flutter analyze`
reports 0 issues, `flutter test` passes all 26 tests (unit tests plus an
app-boot widget smoke test), and `flutter build web --release` succeeds.
Android and Web platform projects are committed in this repo
(`android/`, `web/`); iOS still needs `flutter create --platforms=ios .`
on a Mac since generating it requires Xcode.

## Setup (on a machine with the Flutter SDK installed)

Android and Web platform projects are already committed in this repo.

```bash
# 1. Install dependencies
flutter pub get

# 2. iOS only, and only possible on a Mac with Xcode installed - not
#    needed for Android or Web:
flutter create --platforms=ios .

# 3. (Optional but needed for push notifications) wire up a real Firebase project
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Static analysis and tests
flutter analyze
flutter test

# 5. Run it (pick a connected device/emulator, or Chrome for web)
flutter run
```

If you ever need to regenerate a platform project from scratch,
`flutter create --project-name marocfly_ai --org com.marocfly .` will not
overwrite `lib/main.dart` or `pubspec.yaml` if you answer its prompts
carefully, but review the diff afterwards - it may add its own
`pubspec.yaml` scaffolding that needs merging with the one in this repo.

## Just want to see it running (no computer needed)

If you only have a tablet/phone and no laptop, the simplest path is
deploying the Web build somewhere you can open directly in Safari/Chrome:

1. Push this branch's `build/web` output (after running
   `flutter build web --release`) to GitHub Pages, or connect the repo to
   a static host like Firebase Hosting, Netlify, or Vercel.
2. Open the resulting URL in your tablet's browser - no app store, no
   install, no laptop required. Voice input/output and other native-only
   features won't work in the browser, but the full search/chat/UI flow
   will.
3. For a true native iOS build (e.g. to test via TestFlight on an iPad),
   you need Xcode, which only runs on macOS - either borrow/rent a Mac, or
   use a cloud Mac-build service (e.g. Codemagic) that builds and signs
   the iOS app for you without you owning one.

## Real flight data (Amadeus for Developers)

> **⚠️ Currently blocked for new users.** Amadeus decommissioned the
> self-service developer portal on **July 17, 2026** - new-user
> registration was paused in spring 2026 and the portal (plus all existing
> self-service API keys) is now shut down entirely. Only Amadeus
> **Enterprise** customers (an existing paid/contracted relationship, not
> self-signup) can still use it. This build's `AmadeusFlightPriceSource`
> code is left in place and still works if you have Enterprise credentials
> or the shutdown is reversed, but **no new developer can get self-serve
> Amadeus credentials right now**. Until that changes (or this project
> switches to another source, e.g. Duffel, which is still self-serve), the
> app simply runs on `MockFlightPriceSource` - see "What's mocked" above.

By default the app runs on synthetic flight data (`MockFlightPriceSource`)
so it works fully offline with no setup. If you do have Amadeus
credentials (Enterprise, or from before the shutdown):

1. Create an app in your Amadeus dashboard and copy its **Test
   environment** API Key and API Secret. The sandbox includes a Test Data
   management tool to shape what the API returns, which is why this build
   used Amadeus instead of Duffel while self-service access still existed.
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

## Booking commissions (monetization)

This app has no payment processing or its own flight/rail booking
backend, so it earns money the way Skyscanner/Kayak-style search apps
do: search stays in-app, booking happens on a partner's site via a
tracked affiliate link, and the partner pays a commission when that
booking completes.

1. Join a self-serve flight affiliate network - e.g.
   [Travelpayouts](https://www.travelpayouts.com) (free, instant signup,
   no partner-approval gate). Pick one of its flight programs (Aviasales,
   etc.) and note the affiliate id it gives you (Travelpayouts calls this
   a "marker").
2. Run the app with it as a compile-time define:

   ```bash
   flutter run --dart-define=AFFILIATE_MARKER=your_marker_id
   ```

   Without it, booking links still open (so the UI is fully demoable) but
   use a placeholder `marker=unconfigured` value and earn nothing -
   `AffiliateService.isConfigured` is `false` until you set a real one.
3. If your chosen program's deep-link format differs from the default
   Aviasales-shaped template in `AffiliateService.defaultUrlTemplate`,
   override it: `--dart-define=AFFILIATE_URL_TEMPLATE=...` using the
   placeholders `{origin}`, `{destination}`, `{date}` (ddMMyy), `{marker}`.

Notes/limitations:

- Only flight legs are monetized this way (`ItineraryDetailScreen` shows a
  "Flug buchen" button per flight leg). Train legs (ONCF, ICE) open the
  operator's own site with no commission - there's no rail affiliate
  program integrated.
- A multi-leg itinerary (e.g. the flight+train multimodal option) has to
  be booked leg by leg on each operator's own site, since there is no
  unified checkout across carriers/modes - the UI says so explicitly
  above the leg list when an itinerary has more than one leg.
- "Reisebegleiter aktivieren" (activate travel companion) is currently a
  manual confirmation, not something triggered by an actual verified
  booking - there's no booking-confirmation webhook wired up from the
  affiliate network back into the app.
- See `lib/services/affiliate_service.dart` for the link-building logic
  and `test/affiliate_service_test.dart` for its test coverage.

## Architecture

```
lib/
  core/           theme, localization, shared constants
  models/         Airport, TripLeg, Itinerary, TravelIntent, ChatMessage, ...
  services/       FlightSearchService (+ FlightPriceSource: Mock/Amadeus),
                  NluService, AiAssistantService, VoiceService,
                  NotificationService, TravelCompanionService,
                  PricePredictionService, UserPreferencesService,
                  AffiliateService
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
5. Join a real affiliate program and set `AFFILIATE_MARKER` for production
   (see "Booking commissions" above); consider adding hotel/car-rental
   affiliate links alongside flights/trains, and a booking-confirmation
   webhook so "Reisebegleiter aktivieren" reflects a real booking instead
   of a manual tap.
6. App Store / Play Store assets, privacy policy, and store listings in the
   target languages.
