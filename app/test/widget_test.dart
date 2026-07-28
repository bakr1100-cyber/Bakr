import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marocfly_ai/app/app.dart';

void main() {
  testWidgets('search screen is the initial route and has a search button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MarocFlyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('MarocFly AI'), findsOneWidget);
    expect(find.text('Flug suchen'), findsOneWidget);
  });

  testWidgets('bottom navigation switches to the AI assistant tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MarocFlyApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('KI-Berater'));
    await tester.pumpAndSettle();

    expect(find.text('KI-Reiseberater'), findsOneWidget);
  });
}
