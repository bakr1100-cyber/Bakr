import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_alert.dart';

/// Persists tracked price alerts locally on-device via shared_preferences,
/// same pattern as [UserPreferencesService]. Synced to Firestore per user
/// account by [AccountSyncService] when logged in.
class PriceAlertsService {
  static const _prefsKey = 'price_alerts';

  Future<List<PriceAlert>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    final alerts = <PriceAlert>[];
    for (final entry in decoded) {
      try {
        alerts.add(PriceAlert.fromJson(entry as Map<String, dynamic>));
      } on FormatException {
        // Skip an unparsable entry rather than lose the whole stored list.
        continue;
      }
    }
    return alerts;
  }

  Future<void> save(List<PriceAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(alerts.map((a) => a.toJson()).toList()));
  }
}
