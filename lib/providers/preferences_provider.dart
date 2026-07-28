import 'package:flutter/foundation.dart';

import '../models/user_preferences.dart';
import '../services/user_preferences_service.dart';

class PreferencesProvider extends ChangeNotifier {
  PreferencesProvider({UserPreferencesService? service})
      : _service = service ?? UserPreferencesService();

  final UserPreferencesService _service;
  UserPreferences _preferences = UserPreferences();
  UserPreferences get preferences => _preferences;

  Future<void> load() async {
    _preferences = await _service.load();
    notifyListeners();
  }

  Future<void> update(UserPreferences Function(UserPreferences) updater) async {
    _preferences = updater(_preferences);
    notifyListeners();
    await _service.save(_preferences);
  }
}
