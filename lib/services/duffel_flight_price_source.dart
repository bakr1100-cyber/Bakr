import 'package:flutter/foundation.dart';

import '../models/airport.dart';
import 'duffel_flight_api.dart';
import 'flight_price_source.dart';

/// Real flight quotes via Duffel, falling back to [fallback] (normally
/// [MockFlightPriceSource]) whenever Duffel has no offers for a route/date
/// or the request fails - a missing/invalid API key, being offline, or a
/// route Duffel's sandbox doesn't cover should degrade the app, never
/// crash it.
class DuffelFlightPriceSource implements FlightPriceSource {
  /// Pass [apiKey] to talk to Duffel directly (only safe for builds that
  /// never ship publicly, e.g. native local runs), or [proxyBaseUrl] to
  /// call the `cloudflare-worker/` proxy instead, which holds the real key
  /// server-side - use that for any build that gets deployed publicly
  /// (e.g. GitHub Pages).
  DuffelFlightPriceSource({
    String? apiKey,
    String? proxyBaseUrl,
    required this.fallback,
    DuffelFlightApi? api,
  }) : _api = api ??
            DuffelFlightApi(
              apiKey: apiKey,
              baseUrl: proxyBaseUrl ?? 'https://api.duffel.com',
            );

  final DuffelFlightApi _api;
  final FlightPriceSource fallback;

  @override
  Future<FlightQuote?> quoteDirect({
    required Airport origin,
    required Airport destination,
    required DateTime date,
  }) async {
    try {
      final offers = await _api.searchOneWayOffers(
        originIata: origin.code,
        destinationIata: destination.code,
        departureDate: date,
      );
      if (offers.isEmpty) {
        return fallback.quoteDirect(origin: origin, destination: destination, date: date);
      }

      final cheapest = offers.first;
      if (cheapest.segments.isEmpty) {
        return fallback.quoteDirect(origin: origin, destination: destination, date: date);
      }

      // Duffel-priced amounts aren't guaranteed to be in EUR - the exact
      // currency depends on the route/market. This build treats the
      // numeric amount as EUR for display purposes; a production build
      // should either request/convert to EUR explicitly or show the
      // returned currency code in the UI instead of a hardcoded "€".
      return FlightQuote(
        priceEur: cheapest.totalAmount,
        departure: cheapest.segments.first.departingAt,
        arrival: cheapest.segments.last.arrivingAt,
        carrier: cheapest.segments.first.carrierName,
      );
    } catch (error) {
      debugPrint('DuffelFlightPriceSource: falling back to mock data ($error).');
      return fallback.quoteDirect(origin: origin, destination: destination, date: date);
    }
  }
}
