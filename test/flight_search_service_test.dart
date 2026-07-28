import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/travel_intent.dart';
import 'package:marocfly_ai/services/flight_search_service.dart';

void main() {
  final service = FlightSearchService();

  const dus = Airport(code: 'DUS', city: 'Düsseldorf', country: 'Deutschland');
  const fez = Airport(code: 'FEZ', city: 'Fès', country: 'Marokko');

  test('search returns at least a direct itinerary', () async {
    final results = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 1,
      ),
    );

    expect(results, isNotEmpty);
    expect(results.any((i) => i.isDirect), isTrue);
  });

  test('results are sorted ascending by total price', () async {
    final results = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 1,
      ),
    );

    for (var i = 0; i < results.length - 1; i++) {
      expect(results[i].totalPriceEur, lessThanOrEqualTo(results[i + 1].totalPriceEur));
    }
  });

  test('multimodal option combines more than one transport mode', () async {
    final results = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 1,
      ),
    );

    expect(results.any((i) => i.isMultimodal), isTrue);
  });

  test('budget mode filters results to the requested max price', () async {
    final unfiltered = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 1,
      ),
    );
    final cheapest = unfiltered.map((i) => i.totalPriceEur).reduce((a, b) => a < b ? a : b);

    final budgeted = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 1,
        maxBudgetEur: cheapest + 5,
      ),
    );

    expect(budgeted, isNotEmpty);
    for (final itinerary in budgeted) {
      expect(itinerary.totalPriceEur, lessThanOrEqualTo(cheapest + 5));
    }
  });

  test('budget mode still returns the cheapest option if nothing fits', () async {
    final results = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 1,
        maxBudgetEur: 1,
      ),
    );

    expect(results, hasLength(1));
  });

  test('passenger count multiplies price', () async {
    final onePax = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 1,
      ),
    );
    final fourPax = await service.search(
      TravelIntent(
        origin: dus,
        destination: fez,
        departureDate: DateTime.now().add(const Duration(days: 30)),
        passengerCount: 4,
      ),
    );

    final onePaxDirect = onePax.firstWhere((i) => i.isDirect);
    final fourPaxDirect = fourPax.firstWhere((i) => i.isDirect);
    expect(fourPaxDirect.totalPriceEur, closeTo(onePaxDirect.totalPriceEur * 4, 0.01));
  });
}
