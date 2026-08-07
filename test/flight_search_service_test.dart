import 'package:flutter_test/flutter_test.dart';
import 'package:marocfly_ai/core/localization/app_localizations.dart';
import 'package:marocfly_ai/models/airport.dart';
import 'package:marocfly_ai/models/itinerary.dart';
import 'package:marocfly_ai/models/travel_intent.dart';
import 'package:marocfly_ai/services/flight_price_source.dart';
import 'package:marocfly_ai/services/flight_search_service.dart';
import 'package:marocfly_ai/services/geo.dart';
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

    // Regression test: itinerary explanations used to be hardcoded German
    // text regardless of the app's selected language - confirmed live via a
    // screenshot of a French-language session still showing "Direktflug
    // von ... nach ...".
    test('explanation text is in the language passed to search(), not hardcoded German',
        () async {
      final results = await service.search(intentFor(1), language: AppLanguage.fr);
      final direct = results.firstWhere((i) => i.isDirect);

      expect(direct.explanation, contains('Vol direct'));
      expect(direct.explanation, isNot(contains('Direktflug')));
    });

    test('results are sorted ascending by total price', () async {
      final results = await service.search(intentFor(1));
      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].totalPriceEur, lessThanOrEqualTo(results[i + 1].totalPriceEur));
      }
    });

    test('every alternative-tier result is cheaper than the requested direct route', () async {
      final results = await service.search(intentFor(1));
      // Standard-tier results (direct, and a real layover via Casablanca)
      // are shown regardless of price - only alternative-tier results are
      // required to actually be cheaper.
      final direct = results.firstWhere((i) => i.id.startsWith('direct-'));
      for (final itinerary in results.where((i) => i.tier == ResultTier.alternative)) {
        expect(itinerary.totalPriceEur, lessThan(direct.totalPriceEur));
      }
    });

    test('alternative-tier results carry savings and extra-time data', () async {
      final results = await service.search(intentFor(1));
      for (final itinerary in results.where((i) => i.tier == ResultTier.alternative)) {
        expect(itinerary.savingsEur, isNotNull);
        expect(itinerary.savingsEur, greaterThan(0));
        expect(itinerary.extraTravelTime, isNotNull);
      }
    });

    test('standard-tier results have no savings/extra-time data', () async {
      final results = await service.search(intentFor(1));
      for (final itinerary in results.where((i) => i.tier == ResultTier.standard)) {
        expect(itinerary.savingsEur, isNull);
        expect(itinerary.extraTravelTime, isNull);
      }
    });

    test('reliably surfaces a standard-tier connection via Casablanca', () async {
      final results = await service.search(intentFor(1));
      expect(results.any((i) => i.id.startsWith('connect-')), isTrue);
    });

    test('passenger count multiplies the direct price exactly', () async {
      final onePaxDirect = (await service.search(intentFor(1)))
          .firstWhere((i) => i.id.startsWith('direct-'));
      final fourPaxDirect = (await service.search(intentFor(4)))
          .firstWhere((i) => i.id.startsWith('direct-'));
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

    // Regression test: MockFlightPriceSource used to price every airport
    // pair from the same flat random range, which made the hub+train
    // itinerary (fly into the cheaper Casablanca/Rabat hub, then a short
    // domestic train onward) cheaper than a direct flight to a smaller
    // regional Moroccan airport (like Fès) only ~17% of the time, and made
    // the stopover itinerary cheaper essentially never (0%) - so the
    // "smart engine" rarely had anything but the direct flight to show.
    // Fès isn't a major hub, so this must now reliably surface.
    test('reliably surfaces the hub+train alternative for a non-hub destination', () async {
      final results = await service.search(intentFor(1));
      expect(results.any((i) => i.id.startsWith('althub-')), isTrue);
    });
  });

  group('nearby-airport geography', () {
    const fra = Airport(code: 'FRA', city: 'Frankfurt', country: 'Deutschland', lat: 50.0379, lon: 8.5622);
    const rba = Airport(code: 'RBA', city: 'Rabat', country: 'Marokko', lat: 34.0515, lon: -6.7515);

    // Regression test: searching to Rabat used to never suggest Casablanca
    // (only ~90 km away) because the old hub+train mechanic special-cased
    // Rabat as *only* ever the alternative, never the requested
    // destination. The nearby-destination-airport search is symmetric.
    test('searching to Rabat also offers nearby Casablanca as a swap', () async {
      final service = FlightSearchService(
        priceSource: FakeFlightPriceSource({
          'FRA-RBA': 300,
          'FRA-CMN': 100,
        }),
      );

      final results = await service.search(TravelIntent(
        origin: fra,
        destination: rba,
        departureDate: departureDate,
        passengerCount: 1,
      ));

      final swap = results.where((i) => i.id.startsWith('altdest-')).toList();
      expect(swap, hasLength(1));
      expect(swap.single.id, 'altdest-CMN-RBA');
      expect(swap.single.tier, ResultTier.alternative);
      expect(swap.single.totalPriceEur, lessThan(300));
      expect(swap.single.savingsEur, isNotNull);
    });

    test('does not suggest a nearby-airport swap when it is not actually cheaper', () async {
      final service = FlightSearchService(
        priceSource: FakeFlightPriceSource({
          'FRA-RBA': 100,
          'FRA-CMN': 100, // + transfer cost makes this more expensive than direct
        }),
      );

      final results = await service.search(TravelIntent(
        origin: fra,
        destination: rba,
        departureDate: departureDate,
        passengerCount: 1,
      ));

      expect(results.any((i) => i.id.startsWith('altdest-')), isFalse);
    });

    test('alternative departure airports are picked by real distance, not list order', () async {
      final service = FlightSearchService();
      final results = await service.search(intentFor(1));
      final altDepartures = results.where((i) => i.id.startsWith('altdep-'));
      for (final itinerary in altDepartures) {
        final departureAirport = itinerary.legs.first.from;
        expect(
          distanceKm(dus, departureAirport),
          lessThanOrEqualTo(220),
          reason: '${departureAirport.city} should be within the nearby-departure radius of Düsseldorf',
        );
      }
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
