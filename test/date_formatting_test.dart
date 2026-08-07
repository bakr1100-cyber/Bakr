import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';

void main() {
  // Regression test: the search form and trip-detail screens format dates
  // with `DateFormat.yMMMMd(<app language>)` so the date actually appears
  // in the selected language instead of always in English/German. That
  // call throws a LocaleDataException the first time it runs for *any*
  // locale unless `initializeDateFormatting()` has been called somewhere
  // during startup first (see main.dart) - confirmed live: without it,
  // every non-default-locale date field would crash instead of just
  // showing the wrong language.
  test('every supported language can format a date once initializeDateFormatting() has run',
      () async {
    await initializeDateFormatting();

    for (final language in AppLanguage.values) {
      expect(
        () => DateFormat.yMMMMd(language.flutterLocale.languageCode)
            .format(DateTime(2026, 8, 14)),
        returnsNormally,
        reason: 'DateFormat.yMMMMd should not throw for ${language.code}',
      );
    }

    expect(
      DateFormat.yMMMMd(AppLanguage.fr.flutterLocale.languageCode).format(DateTime(2026, 8, 14)),
      contains('août'),
    );
  });
}
