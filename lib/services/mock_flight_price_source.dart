import 'dart:math';

import '../models/airport.dart';
import 'flight_price_source.dart';

/// Deterministic synthetic pricing used when no real flight API is
/// configured (or as a fallback if the real one errors). Prices are a pure
/// function of the airport pair, so repeated searches for the same route
/// are stable/reproducible instead of drifting between calls.
///
/// Priced in three tiers instead of one flat random range, so the "smart
/// engine" in [FlightSearchService] (alternate departure/hub airports,
/// stopovers, flight+train combos) actually has real-world-shaped economics
/// to find savings in, rather than every airport pair being an equally-
/// priced coin flip: a short intra-Europe or intra-Morocco hop is always
/// much cheaper than a Europe<->Morocco leg, and within Morocco, the two
/// big, competed hubs (Casablanca, Rabat) price lower than the smaller
/// regional airports - which is exactly what makes "fly into the cheaper
/// hub, then a short local hop" a genuine saving instead of a rare fluke.
class MockFlightPriceSource implements FlightPriceSource {
  static const _carriers = [
    'Royal Air Maroc',
    'Ryanair',
    'Air Arabia',
    'Transavia',
    'Vueling',
  ];

  static const _majorMoroccanHubs = {'CMN', 'RBA'};

  @override
  FlightDataMode? get lastDataMode => FlightDataMode.mock;

  @override
  Future<FlightQuote?> quoteDirect({
    required Airport origin,
    required Airport destination,
    required DateTime date,
  }) async {
    final seed =
        (origin.code + destination.code).codeUnits.fold<int>(0, (s, c) => s + c);
    final price = _priceFor(origin, destination, seed);

    return FlightQuote(
      priceEur: price,
      departure: date,
      arrival: date.add(const Duration(hours: 4)),
      carrier: _carriers[seed % _carriers.length],
    );
  }

  double _priceFor(Airport origin, Airport destination, int seed) {
    final originIsMoroccan = origin.country == 'Marokko';
    final destinationIsMoroccan = destination.country == 'Marokko';
    final random = Random(seed);

    // A short regional hop (Europe<->Europe, used by stopover connections,
    // or Morocco<->Morocco, e.g. a domestic onward leg): cheap.
    if (originIsMoroccan == destinationIsMoroccan) {
      return 45 + (seed % 90).toDouble() + random.nextInt(25);
    }

    // Crossing between Europe and Morocco: price depends on which Moroccan
    // airport is involved. The big hubs are cheaper/more competed; smaller
    // regional airports carry a premium - so flying into a hub and
    // continuing locally is a real saving, not a coincidence.
    final moroccanCode = originIsMoroccan ? origin.code : destination.code;
    final isMajorHub = _majorMoroccanHubs.contains(moroccanCode);
    return isMajorHub
        ? 150 + (seed % 120).toDouble() + random.nextInt(30)
        : 230 + (seed % 180).toDouble() + random.nextInt(40);
  }
}
