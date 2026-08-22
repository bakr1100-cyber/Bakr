import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/core/theme/app_theme.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/widgets/city_hero_header.dart';

Widget _app(Widget home, AppLanguage language) => MaterialApp(
      theme: AppTheme.light(),
      locale: language.flutterLocale,
      localizationsDelegates: [
        AppLocalizationsDelegate(language),
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLanguage.values.map((l) => l.flutterLocale),
      home: home,
    );

void main() {
  // A header is only doing its job if the headline fits at the sizes real
  // phones use, in every language - Arabic and French run noticeably longer
  // than German for the same sentence.
  for (final language in AppLanguage.values) {
    testWidgets('header lays out without overflow in ${language.name}', (tester) async {
      tester.view.physicalSize = const Size(750, 1334); // smallest phone still in use
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(
        Scaffold(body: CityHeroHeader(destination: findAirportByCode('CMN'))),
        language,
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
