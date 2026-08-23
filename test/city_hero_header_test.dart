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
    });

    testWidgets('always shows one of the three verified city photos, picked at random',
        (tester) async {
      // Rolled many times so a real implementation bug (e.g. an index out of
      // range, or a stray fourth image) would show up as a flaky/failing
      // assertion rather than getting lucky on a single roll.
      for (var i = 0; i < 20; i++) {
        await _pumpHeader(tester, CityHeroHeader(destination: findAirportByCode('TNG')));
        expect(heroImages, contains(_imageAssetOf(tester)));
      }
    });

    testWidgets('keeps the same photo across rebuilds of the same header instance',
        (tester) async {
      final header = CityHeroHeader(destination: findAirportByCode('FEZ'));
      await _pumpHeader(tester, header);
      final first = _imageAssetOf(tester);

      // Rebuild the same widget instance several times (as happens whenever
      // the screen above it rebuilds for an unrelated reason, e.g. typing a
      // date) - the photo must not flicker between different images.
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(_wrap(header));
        await tester.pump();
        expect(_imageAssetOf(tester), first);
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
