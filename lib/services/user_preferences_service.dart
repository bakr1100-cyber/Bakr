import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';

/// Persists the learned personal-recommendation data described in the
/// brief (favorite airports/airlines, usual budget, family vs. solo)
/// locally on-device via shared_preferences. A production build should
/// sync this to Firestore per user account so it follows the user across
/// devices; the JSON shape here is already ready for that.
class UserPreferencesService {
  static const _prefsKey = 'user_preferences';

  Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return UserPreferences();
    return UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(preferences.toJson()));
  }
}
