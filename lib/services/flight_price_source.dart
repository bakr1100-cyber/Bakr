import '../models/airport.dart';

/// A priced, scheduled nonstop flight leg from one airport to another.
class FlightQuote {
  const FlightQuote({
    required this.priceEur,
    required this.departure,
    required this.arrival,
    required this.carrier,
  });

  final double priceEur;
  final DateTime departure;
  final DateTime arrival;
  final String carrier;
}

/// Source of flight-leg prices/schedules for the [FlightSearchService].
/// Implemented by [MockFlightPriceSource] (synthetic fallback data) and
/// [DuffelFlightPriceSource] (real quotes via the Duffel API). The engine
/// asks this for one nonstop leg at a time - per-passenger price is applied
/// by the caller, not baked in here, so a single quote can be reused across
/// group sizes.
abstract class FlightPriceSource {
  /// Returns a quote for one adult on a nonstop flight from [origin] to
  /// [destination] on [date], or null if no such flight could be priced
  /// (e.g. the real API has no offers for that route/date).
  Future<FlightQuote?> quoteDirect({
    required Airport origin,
    required Airport destination,
    required DateTime date,
  });
}
