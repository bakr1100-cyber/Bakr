import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_language';

  AppLanguage _language = AppLanguage.ary;
  AppLanguage get language => _language;

  bool hasChosenLanguageBefore = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) {
      _language = AppLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.ary,
      );
      hasChosenLanguageBefore = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}
