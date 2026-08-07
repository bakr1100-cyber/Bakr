import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/localization/app_localizations.dart';
import '../models/airport.dart';
import '../models/price_alert.dart';
import '../services/notification_service.dart';

/// Tracked routes the user wants to be pinged about, e.g. "Dein Flug ist
/// heute 52 € günstiger." Price movement is simulated locally - wire
/// [checkForDrops] to a scheduled backend job (Cloud Function + fare cache)
/// polling the real flight API for production.
class PriceAlertsProvider extends ChangeNotifier {
  PriceAlertsProvider({NotificationService? notificationService})
      : _notifications = notificationService ?? NotificationService();

  final NotificationService _notifications;
  final _uuid = const Uuid();
  final _random = Random();

  final List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => List.unmodifiable(_alerts);

  void addAlert(Airport origin, Airport destination, double watchedPriceEur) {
    _alerts.add(
      PriceAlert(
        id: _uuid.v4(),
        origin: origin,
        destination: destination,
        watchedPriceEur: watchedPriceEur,
      ),
    );
    notifyListeners();
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
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
