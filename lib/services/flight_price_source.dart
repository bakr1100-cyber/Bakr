import '../models/airport.dart';

/// Where the prices currently being shown actually came from.
///
/// This exists because "the real flight API answered successfully" and
/// "these are real prices a traveller could actually pay" are two very
/// different things, and the difference is invisible in the response
/// otherwise: a Duffel *test* token returns a fully-formed, realistic
/// looking answer - correct airports, plausible times, real airline names
/// mixed with Duffel's own invented "Duffel Airways" - whose prices are
/// simulated. Showing those to a user as if they were bookable is worse
/// than showing nothing, so the app tracks which of these it's serving and
/// says so (see the banner on the results screen).
enum FlightDataMode {
  /// Synthetic prices computed inside the app ([MockFlightPriceSource]) -
  /// no flight API involved at all.
  mock,

  /// A real flight API, but its test/sandbox environment: realistic-looking
  /// but fictional inventory and prices.
  sandbox,

  /// Real, live market inventory - actual prices, actual availability.
  live,
}

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
/// `AmadeusFlightPriceSource` (real quotes via Amadeus for Developers). The
/// engine asks this for one nonstop leg at a time - per-passenger price is
/// applied by the caller, not baked in here, so a single quote can be
/// reused across group sizes.
abstract class FlightPriceSource {
  /// Returns a quote for one adult on a nonstop flight from [origin] to
  /// [destination] on [date], or null if no such flight could be priced
  /// (e.g. the real API has no offers for that route/date).
  Future<FlightQuote?> quoteDirect({
    required Airport origin,
    required Airport destination,
    required DateTime date,
  });

  /// What the most recently returned quote actually was - null before any
  /// quote has been made. Deliberately reflects what was *served* rather
  /// than what was configured: a source wired to a real API that fell back
  /// to mock data for a route reports [FlightDataMode.mock], because that's
  /// what the user is looking at.
  FlightDataMode? get lastDataMode;
}
