import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/price_alerts_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/language_select_screen.dart';
import 'services/ai_assistant_service.dart';
import 'services/duffel_flight_price_source.dart';
import 'services/flight_search_service.dart';
import 'services/mock_flight_price_source.dart';

/// Set via `flutter run --dart-define=DUFFEL_API_KEY=duffel_test_...` (get a
/// free self-serve test key at https://app.duffel.com). Left empty, the app
/// runs entirely on synthetic mock flight data - see README.md.
const _duffelApiKey = String.fromEnvironment('DUFFEL_API_KEY');

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
    priceSource: _duffelApiKey.isEmpty
        ? MockFlightPriceSource()
        : DuffelFlightPriceSource(
            apiKey: _duffelApiKey,
            fallback: MockFlightPriceSource(),
          ),
  );
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
          create: (_) => SearchProvider(service: _flightSearchService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            assistantService: AiAssistantService(flightSearchService: _flightSearchService),
          ),
        ),
        ChangeNotifierProvider(create: (_) => PriceAlertsProvider()),
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
                locale: localeProvider.language.locale,
                localizationsDelegates: [
                  AppLocalizationsDelegate(localeProvider.language),
                  ...GlobalMaterialLocalizations.delegates,
                ],
                supportedLocales: AppLanguage.values.map((l) => l.locale),
                builder: (context, child) => Directionality(
                  textDirection: localeProvider.language.isRtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: child!,
                ),
                home: localeProvider.hasChosenLanguageBefore
                    ? const HomeScreen()
                    : const LanguageSelectScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
