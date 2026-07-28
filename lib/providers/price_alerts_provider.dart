import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> checkForDrops() async {
    for (final alert in _alerts) {
      final dropChance = _random.nextDouble();
      if (dropChance < 0.4) {
        final drop = 10 + _random.nextInt(60);
        alert.currentPriceEur = alert.watchedPriceEur - drop;
        await _notifications.showLocalNotification(
          title: 'Preisalarm: ${alert.destination.city}',
          body: 'Dein Flug ist heute $drop € günstiger.',
        );
      }
    }
    notifyListeners();
  }
}
