import '../models/flight_option.dart';
import '../models/search_query.dart';
import '../models/transport_leg.dart';

/// Abstraction over a real flight-data source (e.g. Duffel/Kiwi/Amadeus).
///
/// The Smart Flight Engine (see `functions/src/flightEngine`) is the real
/// home for alternate-airport/stopover/multimodal ranking; this client-side
/// interface exists so the app can run against a mock today and swap in a
/// thin wrapper around the `flightEngine` callable function later without
/// touching any UI code.
abstract class FlightProvider {
  Future<List<FlightOption>> search(SearchQuery query);
}

/// Deterministic mock data that mirrors the scenarios from the product
/// vision (alternate airports, stopovers, flight+train combos) so the UI
/// has something realistic to render before a real flight API key exists.
class MockFlightProvider implements FlightProvider {
  @override
  Future<List<FlightOption>> search(SearchQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final departure = query.departureDate;
    final origin = query.origin;
    final destination = query.destination;

    final direct = FlightOption(
      id: 'direct-1',
      strategy: RouteStrategy.direct,
      legs: [
        TransportLeg(
          mode: TransportMode.flight,
          carrier: 'Direct Air',
          from: origin,
          to: destination,
          departure: departure,
          arrival: departure.add(const Duration(hours: 3, minutes: 30)),
        ),
      ],
      totalPrice: 320,
      currency: 'EUR',
      explanation:
          'Der Direktflug von $origin nach $destination ist am bequemsten, '
          'aber nicht die günstigste Option.',
    );

    final viaAlternateAirport = FlightOption(
      id: 'alt-airport-1',
      strategy: RouteStrategy.alternateAirport,
      legs: [
        TransportLeg(
          mode: TransportMode.flight,
          carrier: 'Air Arabia',
          from: origin,
          to: 'Rabat',
          departure: departure,
          arrival: departure.add(const Duration(hours: 3, minutes: 10)),
        ),
        TransportLeg(
          mode: TransportMode.train,
          carrier: 'ONCF',
          from: 'Rabat',
          to: destination,
          departure: departure.add(const Duration(hours: 4)),
          arrival: departure.add(const Duration(hours: 6, minutes: 50)),
        ),
      ],
      totalPrice: 190,
      currency: 'EUR',
      savingsVsCheapestDirect: 130,
      explanation: 'Von Rabat nach $destination fährt ein Zug. '
          'Dadurch sparst du 130 €.',
    );

    final viaStopover = FlightOption(
      id: 'stopover-1',
      strategy: RouteStrategy.stopover,
      legs: [
        TransportLeg(
          mode: TransportMode.flight,
          carrier: 'Ryanair',
          from: origin,
          to: 'Madrid',
          departure: departure,
          arrival: departure.add(const Duration(hours: 2)),
        ),
        TransportLeg(
          mode: TransportMode.flight,
          carrier: 'Air Arabia',
          from: 'Madrid',
          to: destination,
          departure: departure.add(const Duration(hours: 4)),
          arrival: departure.add(const Duration(hours: 6, minutes: 15)),
        ),
      ],
      totalPrice: 180,
      currency: 'EUR',
      savingsVsCheapestDirect: 140,
      explanation:
          'Mit einem Zwischenstopp in Madrid sparst du 140 €.',
    );

    final multimodal = FlightOption(
      id: 'multimodal-1',
      strategy: RouteStrategy.multimodal,
      legs: [
        TransportLeg(
          mode: TransportMode.train,
          carrier: 'ICE',
          from: origin,
          to: 'Frankfurt',
          departure: departure.subtract(const Duration(hours: 2)),
          arrival: departure.subtract(const Duration(hours: 1)),
        ),
        TransportLeg(
          mode: TransportMode.flight,
          carrier: 'Royal Air Maroc',
          from: 'Frankfurt',
          to: 'Rabat',
          departure: departure,
          arrival: departure.add(const Duration(hours: 3, minutes: 20)),
        ),
        TransportLeg(
          mode: TransportMode.train,
          carrier: 'ONCF',
          from: 'Rabat',
          to: destination,
          departure: departure.add(const Duration(hours: 4)),
          arrival: departure.add(const Duration(hours: 6, minutes: 50)),
        ),
      ],
      totalPrice: 170,
      currency: 'EUR',
      savingsVsCheapestDirect: 180,
      explanation: 'ICE + Flug + Zug: die günstigste Kombination. '
          'Ersparnis: 180 € gegenüber dem Direktflug.',
    );

    final options = [direct, viaAlternateAirport, viaStopover, multimodal];
    if (query.maxBudget != null) {
      options.retainWhere((o) => o.totalPrice <= query.maxBudget!);
    }
    options.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    return options;
  }
}
