import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/widgets/city_hero_header.dart';

Widget _wrap(Widget child, {AppLanguage language = AppLanguage.de}) {
  return MaterialApp(
    locale: language.flutterLocale,
    localizationsDelegates: [
      AppLocalizationsDelegate(language),
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLanguage.values.map((l) => l.flutterLocale),
    home: Scaffold(body: child),
  );
}

/// Localization delegates resolve asynchronously, so the very first frame
/// after pumpWidget is still empty - everything here needs one more frame
/// before the header has actually rendered.
Future<void> _pumpHeader(WidgetTester tester, Widget child,
    {AppLanguage language = AppLanguage.de}) async {
  await tester.pumpWidget(_wrap(child, language: language));
  await tester.pump();
}

String _imageAssetOf(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image).first);
  return (image.image as AssetImage).assetName;
}

void main() {
  group('CityHeroHeader', () {
    testWidgets('names the destination in the headline', (tester) async {
      await _pumpHeader(tester, CityHeroHeader(destination: findAirportByCode('FEZ')));

      expect(find.textContaining('Fès', findRichText: true), findsOneWidget);
    });

    testWidgets('falls back to the country when no destination is chosen yet', (tester) async {
      await _pumpHeader(tester, const CityHeroHeader());

      expect(find.textContaining('Marokko', findRichText: true), findsOneWidget);
      expect(_imageAssetOf(tester), 'assets/images/hero_morocco.jpg');
    });

    testWidgets('uses the city photo only where the photo really shows that city', (tester) async {
      await _pumpHeader(tester, CityHeroHeader(destination: findAirportByCode('FEZ')));
      expect(_imageAssetOf(tester), 'assets/images/hero_fes.jpg');
    });

    testWidgets('uses each verified city\'s own photo, never another city\'s', (tester) async {
      const verified = {
        'FEZ': 'assets/images/hero_fes.jpg',
        'CMN': 'assets/images/hero_casablanca.jpg',
        'RAK': 'assets/images/hero_marrakech.jpg',
      };
      for (final entry in verified.entries) {
        final airport = findAirportByCode(entry.key);
        if (airport == null) continue;
        await _pumpHeader(tester, CityHeroHeader(destination: airport));
        expect(_imageAssetOf(tester), entry.value, reason: '${entry.key} has its own photo');
      }
    });

    testWidgets('shows Morocco - never another city\'s photo - for a city with no picture of '
        'its own, since a wrong landmark is worse than a generic one', (tester) async {
      for (final code in ['RBA', 'AGA', 'TNG']) {
        final airport = findAirportByCode(code);
        if (airport == null) continue;
        await _pumpHeader(tester, CityHeroHeader(destination: airport));
        expect(_imageAssetOf(tester), 'assets/images/hero_morocco.jpg',
            reason: '$code has no verified photo of its own');
      }
    });

    testWidgets('greets in the selected language', (tester) async {
      await _pumpHeader(tester, const CityHeroHeader(), language: AppLanguage.fr);

      expect(find.textContaining('SALAM ET BIENVENUE'), findsOneWidget);
      expect(find.textContaining('Maroc', findRichText: true), findsOneWidget);
    });

    testWidgets('renders a trailing action when one is given', (tester) async {
      await _pumpHeader(
          tester, const CityHeroHeader(trailing: Icon(Icons.notifications_rounded)));

      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    });
  });
}
