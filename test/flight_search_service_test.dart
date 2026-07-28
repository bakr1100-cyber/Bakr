import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/travel_intent.dart';
import 'package:marocfly_ai/services/flight_price_source.dart';
import 'package:marocfly_ai/services/flight_search_service.dart';
import 'package:marocfly_ai/services/mock_flight_price_source.dart';

/// A fully controllable [FlightPriceSource] for tests: returns a fixed
/// price for each "ORIGIN-DEST" pair given, or null (no offer) for
/// anything not listed. This lets tests assert exact behaviour (e.g. "the
/// multimodal option is surfaced and priced at X") without depending on
/// [MockFlightPriceSource]'s pseudo-random internals.
class FakeFlightPriceSource implements FlightPriceSource {
  FakeFlightPriceSource(this.prices);

  final Map<String, double> prices;

  @override
  Future<FlightQuote?> quoteDirect({
    required Airport origin,
    required Airport destination,
    required DateTime date,
  }) async {
    final price = prices['${origin.code}-${destination.code}'];
    if (price == null) return null;
    return FlightQuote(
      priceEur: price,
      departure: date,
      arrival: date.add(const Duration(hours: 4)),
      carrier: 'TestAir',
    );
  }
}

void main() {
  const dus = Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland');
  const fez = Airport(code: 'FEZ', city: 'Fès', country: 'Marokko');
  final departureDate = DateTime.now().add(const Duration(days: 30));

  TravelIntent intentFor(int pax, {double? maxBudgetEur}) => TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: departureDate,
        passengerCount: pax,
        maxBudgetEur: maxBudgetEur,
      );

  group('with the default (mock) price source', () {
    final service = FlightSearchService();

    test('always returns a direct itinerary', () async {
      final results = await service.search(intentFor(1));
      expect(results, isNotEmpty);
      expect(results.any((i) => i.isDirect), isTrue);
    });

    test('results are sorted ascending by total price', () async {
      final results = await service.search(intentFor(1));
      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].totalPriceEur, lessThanOrEqualTo(results[i + 1].totalPriceEur));
      }
    });

    test('every non-direct alternative is cheaper than the direct flight', () async {
      final results = await service.search(intentFor(1));
      final direct = results.firstWhere((i) => i.isDirect);
      for (final itinerary in results.where((i) => !i.isDirect)) {
        expect(itinerary.totalPriceEur, lessThan(direct.totalPriceEur));
      }
    });

    test('passenger count multiplies the direct price exactly', () async {
      final onePaxDirect =
          (await service.search(intentFor(1))).firstWhere((i) => i.isDirect);
      final fourPaxDirect =
          (await service.search(intentFor(4))).firstWhere((i) => i.isDirect);
      expect(fourPaxDirect.totalPriceEur, closeTo(onePaxDirect.totalPriceEur * 4, 0.01));
    });

    test('budget mode filters results to the requested max price', () async {
      final unfiltered = await service.search(intentFor(1));
      final cheapest =
          unfiltered.map((i) => i.totalPriceEur).reduce((a, b) => a < b ? a : b);

      final budgeted = await service.search(intentFor(1, maxBudgetEur: cheapest + 5));

      expect(budgeted, isNotEmpty);
      for (final itinerary in budgeted) {
        expect(itinerary.totalPriceEur, lessThanOrEqualTo(cheapest + 5));
      }
    });

    test('budget mode still returns the cheapest option if nothing fits', () async {
      final results = await service.search(intentFor(1, maxBudgetEur: 1));
      expect(results, hasLength(1));
    });
  });

  group('with a controlled fake price source', () {
    test('surfaces the multimodal route when it is cheaper than direct', () async {
      final service = FlightSearchService(
        priceSource: FakeFlightPriceSource({
          'DUS-FEZ': 320,
          'FRA-RBA': 60,
        }),
      );

      final results = await service.search(intentFor(1));
      final multimodal = results.where((i) => i.isMultimodal).toList();

      expect(multimodal, hasLength(1));
      // ICE (35) + flight Frankfurt->Rabat (60) + ONCF onward (18) = 113
      expect(multimodal.single.totalPriceEur, closeTo(113, 0.01));
      expect(multimodal.single.totalPriceEur, lessThan(320));
    });

    test('does not surface alternatives that are not actually cheaper', () async {
      final service = FlightSearchService(
        priceSource: FakeFlightPriceSource({
          'DUS-FEZ': 100,
          'FRA-RBA': 90, // multimodal total (35+90+18=143) is more than direct
        }),
      );

      final results = await service.search(intentFor(1));
      expect(results, hasLength(1));
      expect(results.single.isDirect, isTrue);
    });

    test('falls back to no results when even the direct route has no offer', () async {
      final service = FlightSearchService(priceSource: FakeFlightPriceSource({}));
      final results = await service.search(intentFor(1));
      expect(results, isEmpty);
    });
  });
}
