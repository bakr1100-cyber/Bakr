import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marocfly_ai/app.dart';
import 'package:marocfly_ai/providers/home_navigation_provider.dart';
import 'package:marocfly_ai/screens/home/home_screen.dart';
import 'package:marocfly_ai/screens/onboarding/mode_select_screen.dart';

void main() {
  // Drives the real app (same boot path proven in widget_test.dart) through
  // language selection to reach ModeSelectScreen, rather than hand-wiring
  // every provider HomeScreen's five tabs need just for this test.
  Future<void> tapThroughToModeSelect(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MarocFlyApp());
    await tester.pumpAndSettle();

    // The language grid can exceed the default test viewport height, so the
    // German card may start out laid out but off-screen inside the
    // SingleChildScrollView - scroll it into view before tapping.
    await tester.ensureVisible(find.text('Deutsch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.byType(ModeSelectScreen), findsOneWidget);
  }

  testWidgets('choosing the AI card lands on HomeScreen with the assistant tab active',
      (tester) async {
    await tapThroughToModeSelect(tester);

    await tester.tap(find.text('KI-Assistent'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final navigation =
        tester.element(find.byType(HomeScreen)).read<HomeNavigationProvider>();
    expect(navigation.tabIndex, HomeNavigationProvider.assistantTabIndex);
  });

  testWidgets('choosing the classic-search card lands on HomeScreen with the search tab active',
      (tester) async {
    await tapThroughToModeSelect(tester);

    await tester.tap(find.text('Klassische Suche'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final navigation =
        tester.element(find.byType(HomeScreen)).read<HomeNavigationProvider>();
    expect(navigation.tabIndex, 0);
  });
}
