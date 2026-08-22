import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marocfly_ai/app.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/providers/search_provider.dart';
import 'package:marocfly_ai/screens/search/search_form_screen.dart';
import 'package:marocfly_ai/widgets/city_hero_header.dart';

void main() {
  // Drives the real app to the search tab, same approach as
  // mode_select_screen_test - the point is to exercise the screen exactly as
  // it is assembled in production, since the header was slotted into an
  // existing layout and a nesting mistake there would only show up here.
  Future<void> openSearchTab(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MarocFlyApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Deutsch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Klassische Suche'));
    await tester.pumpAndSettle();
  }

  testWidgets('the search screen shows the photo header and lays out cleanly', (tester) async {
    tester.view.physicalSize = const Size(828, 1792);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await openSearchTab(tester);

    expect(find.byType(SearchFormScreen), findsOneWidget);
    expect(find.byType(CityHeroHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the header follows the destination the traveller picks', (tester) async {
    tester.view.physicalSize = const Size(828, 1792);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await openSearchTab(tester);

    // Set it through the provider rather than driving the picker UI: this
    // test is about the header reacting, not about how the airport gets
    // chosen.
    final search = tester.element(find.byType(SearchFormScreen)).read<SearchProvider>();
    search.setDestination(findAirportByCode('FEZ')!);
    await tester.pumpAndSettle();

    final header = tester.widget<CityHeroHeader>(find.byType(CityHeroHeader));
    expect(header.destination?.code, 'FEZ');
    expect(find.textContaining('Fès', findRichText: true), findsWidgets);
  });
}
