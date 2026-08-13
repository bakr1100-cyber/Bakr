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

  FlightDataMode? _lastDataMode;

  @override
  FlightDataMode? get lastDataMode => _lastDataMode;

  /// Falls back and records that mock data - not Duffel's - is what the
  /// caller is actually getting, so the UI can be honest about it.
  Future<FlightQuote?> _fallback(Airport origin, Airport destination, DateTime date) {
    _lastDataMode = fallback.lastDataMode ?? FlightDataMode.mock;
    return fallback.quoteDirect(origin: origin, destination: destination, date: date);
  }

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
      if (offers.isEmpty) return _fallback(origin, destination, date);

      // The whole app prices and displays in euros. Duffel returns
      // whatever currency the airline/market priced in, so picking the
      // numerically cheapest offer across mixed currencies would compare
      // e.g. 90 GBP against 95 EUR and label the result "€90" - a wrong
      // price, silently. Prefer genuine EUR offers; only if none exist at
      // all does this fall back rather than mislabel a foreign amount.
      final euroOffers = offers.where((o) => o.totalCurrency.toUpperCase() == 'EUR').toList();
      if (euroOffers.isEmpty) {
        debugPrint(
          'DuffelFlightPriceSource: no EUR-priced offers for '
          '${origin.code}->${destination.code} (got '
          '${offers.map((o) => o.totalCurrency).toSet().join(", ")}) - '
          'falling back rather than showing a foreign amount as euros.',
        );
        return _fallback(origin, destination, date);
      }

      final cheapest = euroOffers.first;
      if (cheapest.segments.isEmpty) return _fallback(origin, destination, date);

      // The single most important bit of bookkeeping here: a *test* Duffel
      // token returns a perfectly well-formed answer whose prices are
      // invented. Record which we got, so the app can tell the user
      // whether these are prices they can actually act on.
      _lastDataMode = cheapest.isLiveMode ? FlightDataMode.live : FlightDataMode.sandbox;

      return FlightQuote(
        priceEur: cheapest.totalAmount,
        departure: cheapest.segments.first.departingAt,
        arrival: cheapest.segments.last.arrivingAt,
        carrier: cheapest.segments.first.carrierName,
      );
    } catch (error) {
      debugPrint('DuffelFlightPriceSource: falling back to mock data ($error).');
      return _fallback(origin, destination, date);
    }
  }
}
