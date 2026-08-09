import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/price_alert.dart';

void main() {
  group('PriceAlert JSON', () {
    test('round-trips through toJson/fromJson by looking airports back up by code', () {
      final alert = PriceAlert(
        id: 'a1',
        origin: findAirportByCode('DUS')!,
        destination: findAirportByCode('FEZ')!,
        watchedPriceEur: 199.5,
        currentPriceEur: 150,
      );

      final restored = PriceAlert.fromJson(alert.toJson());

      expect(restored.id, alert.id);
      expect(restored.origin, alert.origin);
      expect(restored.destination, alert.destination);
      expect(restored.watchedPriceEur, alert.watchedPriceEur);
      expect(restored.currentPriceEur, alert.currentPriceEur);
    });

    test('a null currentPriceEur round-trips as null', () {
      final alert = PriceAlert(
        id: 'a2',
        origin: findAirportByCode('CDG')!,
        destination: findAirportByCode('RAK')!,
        watchedPriceEur: 250,
      );

      final restored = PriceAlert.fromJson(alert.toJson());

      expect(restored.currentPriceEur, isNull);
    });

    test('fromJson throws FormatException for an unknown airport code', () {
      expect(
        () => PriceAlert.fromJson({
          'id': 'x',
          'originCode': 'ZZZ',
          'destinationCode': 'FEZ',
          'watchedPriceEur': 100.0,
          'currentPriceEur': null,
        }),
        throwsFormatException,
      );
    });
  });
}
