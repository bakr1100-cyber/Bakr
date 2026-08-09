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

  /// Overwrites the preferences outright, e.g. with data pulled from the
  /// user's account by [AccountSyncService] - doesn't re-push to the cloud
  /// itself (the caller is the one that just fetched this from there).
  Future<void> replaceAll(UserPreferences preferences) async {
    _preferences = preferences;
    notifyListeners();
    await _service.save(_preferences);
  }
}
