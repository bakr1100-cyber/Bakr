import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marocfly_ai/app.dart';

void main() {
  testWidgets('MarocFlyApp boots to the language selector without crashing',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MarocFlyApp());
    // Let the async bootstrap (loading locale/theme/preferences) settle.
    await tester.pumpAndSettle();

    expect(find.text('MarocFly AI'), findsOneWidget);
  });
}
