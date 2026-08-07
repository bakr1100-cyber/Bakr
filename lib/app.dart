import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/home_navigation_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/price_alerts_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding/language_select_screen.dart';
import 'services/affiliate_service.dart';
import 'services/ai_assistant_service.dart';
import 'services/amadeus_flight_price_source.dart';
import 'services/duffel_flight_price_source.dart';
import 'services/flight_price_source.dart';
import 'services/flight_search_service.dart';
import 'services/llm_chat_service.dart';
import 'services/mock_flight_price_source.dart';

/// Set via
/// `flutter run --dart-define=DUFFEL_PROXY_URL=https://marocfly-duffel-proxy.<you>.workers.dev`
/// (see `cloudflare-worker/`). Routes flight searches through our own
/// server, which holds the real Duffel key - use this for any build that
/// gets deployed publicly (e.g. GitHub Pages), since a key passed directly
/// via [_duffelApiKey] would ship in plain text inside the compiled web
/// bundle. Checked first, ahead of a direct key.
///
/// The same Worker also serves `/ai/chat` (a free LLM via Cloudflare
/// Workers AI, see [LlmChatService]), so this one URL powers both.
const _duffelProxyUrl = String.fromEnvironment('DUFFEL_PROXY_URL');

/// Set via `flutter run --dart-define=DUFFEL_API_KEY=duffel_test_...` (get a
/// free self-serve test key at https://app.duffel.com - no approval wait,
/// unlike Amadeus's now-defunct self-service program or Skyscanner). Only
/// safe for builds that never get deployed publicly (e.g. a native app you
/// run locally) - for anything public, use [_duffelProxyUrl] instead.
const _duffelApiKey = String.fromEnvironment('DUFFEL_API_KEY');

/// Set via
/// `flutter run --dart-define=AMADEUS_CLIENT_ID=... --dart-define=AMADEUS_CLIENT_SECRET=...`
/// Amadeus's self-service portal was decommissioned July 17, 2026 - this
/// only works with Enterprise credentials now (see README.md) - kept as a
/// fallback in case that access exists or the situation changes. Only used
/// if [_duffelApiKey] is not set.
const _amadeusClientId = String.fromEnvironment('AMADEUS_CLIENT_ID');
const _amadeusClientSecret = String.fromEnvironment('AMADEUS_CLIENT_SECRET');

/// Set via `flutter run --dart-define=AFFILIATE_MARKER=...` (join a flight
/// program at https://www.travelpayouts.com or similar and use the
/// affiliate id/"marker" it gives you). Left empty, booking links still
/// work but earn no commission - see README.md.
const _affiliateMarker = String.fromEnvironment('AFFILIATE_MARKER');
const _affiliateUrlTemplateOverride = String.fromEnvironment('AFFILIATE_URL_TEMPLATE');

class MarocFlyApp extends StatefulWidget {
  const MarocFlyApp({super.key});

  @override
  State<MarocFlyApp> createState() => _MarocFlyAppState();
}

class _MarocFlyAppState extends State<MarocFlyApp> {
  final _localeProvider = LocaleProvider();
  final _themeProvider = ThemeProvider();
  final _preferencesProvider = PreferencesProvider();
  late final FlightSearchService _flightSearchService = FlightSearchService(
    priceSource: _resolvePriceSource(),
  );

  static FlightPriceSource _resolvePriceSource() {
    if (_duffelProxyUrl.isNotEmpty) {
      return DuffelFlightPriceSource(
        proxyBaseUrl: _duffelProxyUrl,
        fallback: MockFlightPriceSource(),
      );
    }
    if (_duffelApiKey.isNotEmpty) {
      return DuffelFlightPriceSource(
        apiKey: _duffelApiKey,
        fallback: MockFlightPriceSource(),
      );
    }
    if (_amadeusClientId.isNotEmpty && _amadeusClientSecret.isNotEmpty) {
      return AmadeusFlightPriceSource(
        clientId: _amadeusClientId,
        clientSecret: _amadeusClientSecret,
        fallback: MockFlightPriceSource(),
      );
    }
    return MockFlightPriceSource();
  }
  late final AffiliateService _affiliateService = AffiliateService(
    marker: _affiliateMarker,
    urlTemplate: _affiliateUrlTemplateOverride.isEmpty
        ? AffiliateService.defaultUrlTemplate
        : _affiliateUrlTemplateOverride,
  );
  late final LlmChatService _llmChatService = LlmChatService(proxyBaseUrl: _duffelProxyUrl);
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _localeProvider.load(),
      _themeProvider.load(),
      _preferencesProvider.load(),
    ]);
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localeProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _preferencesProvider),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(
            service: _flightSearchService,
            preferences: _preferencesProvider,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            assistantService: AiAssistantService(
              flightSearchService: _flightSearchService,
              llmChatService: _llmChatService,
            ),
            language: _localeProvider.language,
          ),
        ),
        ChangeNotifierProvider(create: (_) => PriceAlertsProvider()),
        ChangeNotifierProvider(create: (_) => HomeNavigationProvider()),
        Provider<AffiliateService>.value(value: _affiliateService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return MaterialApp(
                title: 'MarocFly AI',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: themeProvider.mode,
                locale: localeProvider.language.flutterLocale,
                localizationsDelegates: [
                  AppLocalizationsDelegate(localeProvider.language),
                  ...GlobalMaterialLocalizations.delegates,
                ],
                supportedLocales: AppLanguage.values.map((l) => l.flutterLocale),
                // The app's screens are not yet fully translated (most UI
                // strings are still hardcoded German regardless of the
                // selected language) - mirroring the whole layout to RTL for
                // Darija/Arabic on top of that produces a broken mix (nav
                // bar/fields/buttons flipped, but the text on them still
                // German). Actual Arabic/Darija script still shapes and
                // reads correctly right-to-left on its own regardless of
                // this - Unicode bidi handles that per text run - so this
                // only holds off on mirroring the surrounding UI chrome
                // until it's genuinely translated everywhere.
                builder: (context, child) => Directionality(
                  textDirection: TextDirection.ltr,
                  child: child!,
                ),
                // Per explicit request: don't skip the language picker on
                // repeat launches for now, even though a language is saved
                // and can still be changed anytime from Settings. Revisit
                // once that's confirmed as the wanted long-term behavior.
                home: const LanguageSelectScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
