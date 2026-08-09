import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/localization/app_localizations.dart';
import '../models/airport.dart';
import '../models/price_alert.dart';
import '../services/notification_service.dart';
import '../services/price_alerts_service.dart';

/// Tracked routes the user wants to be pinged about, e.g. "Dein Flug ist
/// heute 52 € günstiger." Price movement is simulated locally - wire
/// [checkForDrops] to a scheduled backend job (Cloud Function + fare cache)
/// polling the real flight API for production.
class PriceAlertsProvider extends ChangeNotifier {
  PriceAlertsProvider({NotificationService? notificationService, PriceAlertsService? service})
      : _notifications = notificationService ?? NotificationService(),
        _service = service ?? PriceAlertsService();

  final NotificationService _notifications;
  final PriceAlertsService _service;
  final _uuid = const Uuid();
  final _random = Random();

  final List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => List.unmodifiable(_alerts);

  Future<void> load() async {
    final stored = await _service.load();
    _alerts
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  /// Overwrites the full list, e.g. with data pulled from the user's
  /// account by [AccountSyncService] - doesn't re-push to the cloud itself
  /// (the caller is the one that just fetched this from there).
  Future<void> replaceAll(List<PriceAlert> alerts) async {
    _alerts
      ..clear()
      ..addAll(alerts);
    notifyListeners();
    await _service.save(_alerts);
  }

  /// Returns `false` without adding anything if this route is already being
  /// watched - tapping "Preis beobachten" twice on the same itinerary (e.g.
  /// because the confirmation wasn't noticed the first time) used to create
  /// silently duplicate rows in Price Alerts.
  bool addAlert(Airport origin, Airport destination, double watchedPriceEur) {
    final alreadyWatched =
        _alerts.any((a) => a.origin == origin && a.destination == destination);
    if (alreadyWatched) return false;
    _alerts.add(
      PriceAlert(
        id: _uuid.v4(),
        origin: origin,
        destination: destination,
        watchedPriceEur: watchedPriceEur,
      ),
    );
    notifyListeners();
    unawaited(_service.save(_alerts));
    return true;
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
    unawaited(_service.save(_alerts));
  }

  /// Re-inserts an alert at [index], e.g. to undo [removeAlert] - restores
  /// the same object (including its `currentPriceEur`) rather than a fresh
  /// one, and clamps the index so it still works if the list shrank further
  /// in the meantime.
  void restoreAlert(int index, PriceAlert alert) {
    _alerts.insert(index.clamp(0, _alerts.length), alert);
    notifyListeners();
    unawaited(_service.save(_alerts));
  }

  /// Returns how many alerts got a (simulated) price drop this run, so the
  /// caller can confirm the check in-app - system notifications alone
  /// aren't reliable feedback: they're a no-op on web (see
  /// [NotificationService]) and even on a platform that supports them, the
  /// user might not see one land while they're already looking at this
  /// screen.
  Future<int> checkForDrops({required AppLanguage language}) async {
    var dropsFound = 0;
    for (final alert in _alerts) {
      final dropChance = _random.nextDouble();
      if (dropChance < 0.4) {
        final drop = 10 + _random.nextInt(60);
        alert.currentPriceEur = alert.watchedPriceEur - drop;
        dropsFound++;
        await _notifications.showLocalNotification(
          title: _alertTitle(language, alert.destination.city),
          body: _alertBody(language, drop),
        );
      }
    }
    notifyListeners();
    if (dropsFound > 0) unawaited(_service.save(_alerts));
    return dropsFound;
  }

  String _alertTitle(AppLanguage language, String destinationCity) => switch (language) {
        AppLanguage.de => 'Preisalarm: $destinationCity',
        AppLanguage.fr => 'Alerte prix : $destinationCity',
        AppLanguage.en => 'Price alert: $destinationCity',
        AppLanguage.ar => 'تنبيه السعر: $destinationCity',
        AppLanguage.ary => 'تنبيه الثمن: $destinationCity',
      };

  String _alertBody(AppLanguage language, int drop) => switch (language) {
        AppLanguage.de => 'Dein Flug ist heute $drop € günstiger.',
        AppLanguage.fr => "Ton vol est moins cher de $drop € aujourd'hui.",
        AppLanguage.en => 'Your flight is €$drop cheaper today.',
        AppLanguage.ar => 'رحلتك أرخص بـ $drop € اليوم.',
        AppLanguage.ary => 'الطيران ديالك رخص ب $drop € اليوم.',
      };
}
