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

    // Default language is Darija (AppLanguage.ary), so the app name renders
    // in Arabic script - see the 'appName' localization entry.
    expect(find.text('طيارتي'), findsOneWidget);
  });
}
