import 'dart:math';

import '../models/airport.dart';
import 'flight_price_source.dart';

/// Deterministic synthetic pricing used when no real flight API is
/// configured (or as a fallback if the real one errors). Prices are a pure
/// function of the airport pair, so repeated searches for the same route
/// are stable/reproducible instead of drifting between calls.
class MockFlightPriceSource implements FlightPriceSource {
  static const _carriers = [
    'Royal Air Maroc',
    'Ryanair',
    'Air Arabia',
    'Transavia',
    'Vueling',
  ];

  @override
  Future<FlightQuote?> quoteDirect({
    required Airport origin,
    required Airport destination,
    required DateTime date,
  }) async {
    final seed =
        (origin.code + destination.code).codeUnits.fold<int>(0, (s, c) => s + c);
    final price = 180 + (seed % 220).toDouble() + Random(seed).nextInt(40);

    return FlightQuote(
      priceEur: price,
      departure: date,
      arrival: date.add(const Duration(hours: 4)),
      carrier: _carriers[seed % _carriers.length],
    );
  }
}
