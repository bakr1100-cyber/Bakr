import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/providers/price_alerts_provider.dart';
import 'package:marocfly_ai/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts calls instead of actually touching a platform channel, so this
/// test never depends on `flutter_local_notifications`' (lack of) web
/// support - see [NotificationService]'s class doc.
class _CountingNotificationService implements NotificationService {
  int calls = 0;

  @override
  Future<bool> showLocalNotification({required String title, required String body}) async {
    calls++;
    return true;
  }

  @override
  Future<void> init() async {}

  @override
  bool get isPushEnabled => false;
}

void main() {
  const dus = Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland');
  const fez = Airport(code: 'FEZ', city: 'Fès', country: 'Marokko');

  group('PriceAlertsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Regression test: checkForDrops() used to return void, so the UI had
    // no way to confirm the result in-app - the only feedback was a system
    // notification, which is a guaranteed no-op on the deployed web build
    // (flutter_local_notifications 17.2.4 has no web implementation).
    test('checkForDrops reports exactly as many drops as it actually applied', () async {
      final notifications = _CountingNotificationService();
      final provider = PriceAlertsProvider(notificationService: notifications);
      // 30 *distinct* routes - addAlert() now de-duplicates by
      // origin/destination (see the "duplicate alert" test below), so
      // repeating the same pair would only ever create one alert.
      for (var i = 0; i < 30; i++) {
        provider.addAlert(
          europeanAirports[i % europeanAirports.length],
          moroccanAirports[i % moroccanAirports.length],
          300,
        );
      }

      final dropsFound = await provider.checkForDrops(language: AppLanguage.de);

      final alertsWithDrop = provider.alerts.where((a) => a.currentPriceEur != null).length;
      expect(dropsFound, alertsWithDrop);
      expect(notifications.calls, dropsFound);
      expect(dropsFound, greaterThan(0)); // 30 alerts at 40% chance each - vanishingly unlikely to be 0
      for (final alert in provider.alerts) {
        if (alert.currentPriceEur != null) {
          expect(alert.dropEur, greaterThan(0));
        }
      }
    });

    test('checkForDrops returns 0 and touches nothing when there are no alerts', () async {
      final notifications = _CountingNotificationService();
      final provider = PriceAlertsProvider(notificationService: notifications);

      final dropsFound = await provider.checkForDrops(language: AppLanguage.en);

      expect(dropsFound, 0);
      expect(notifications.calls, 0);
    });

    test('addAlert does not create a duplicate for a route already being watched', () {
      final provider = PriceAlertsProvider(notificationService: _CountingNotificationService());

      final firstAdded = provider.addAlert(dus, fez, 300);
      final secondAdded = provider.addAlert(dus, fez, 280);

      expect(firstAdded, isTrue);
      expect(secondAdded, isFalse);
      expect(provider.alerts, hasLength(1));
      expect(provider.alerts.single.watchedPriceEur, 300);
    });

    test('restoreAlert re-inserts a removed alert at the same position', () async {
      final provider = PriceAlertsProvider(notificationService: _CountingNotificationService());
      provider.addAlert(dus, fez, 300);
      const rak = Airport(code: 'RAK', city: 'Marrakech', country: 'Marokko');
      provider.addAlert(dus, rak, 250);
      final removed = provider.alerts.first;

      provider.removeAlert(removed.id);
      expect(provider.alerts, hasLength(1));

      provider.restoreAlert(0, removed);

      expect(provider.alerts, hasLength(2));
      expect(provider.alerts.first.id, removed.id);
    });
  });
}
