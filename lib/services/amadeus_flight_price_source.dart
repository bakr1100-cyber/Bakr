import 'package:flutter/foundation.dart';

import '../models/airport.dart';
import 'amadeus_flight_api.dart';
import 'flight_price_source.dart';

/// Real flight quotes via Amadeus for Developers, falling back to
/// [fallback] (normally [MockFlightPriceSource]) whenever Amadeus has no
/// offers for a route/date or the request fails. The Amadeus sandbox has
/// limited coverage of smaller regional airports (e.g. Nador, Oujda), so
/// falling back gracefully is the common case for those routes, not just
/// an error path.
class AmadeusFlightPriceSource implements FlightPriceSource {
  AmadeusFlightPriceSource({
    required String clientId,
    required String clientSecret,
    required this.fallback,
    AmadeusFlightApi? api,
  }) : _api = api ?? AmadeusFlightApi(clientId: clientId, clientSecret: clientSecret);

  final AmadeusFlightApi _api;
  final FlightPriceSource fallback;

  FlightDataMode? _lastDataMode;

  @override
  FlightDataMode? get lastDataMode => _lastDataMode;

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
      final offers = await _api.searchFlightOffers(
        originIata: origin.code,
        destinationIata: destination.code,
        departureDate: date,
      );
      if (offers.isEmpty) return _fallback(origin, destination, date);

      final cheapest = offers.first;
      // Amadeus splits test vs production by hostname, not a per-offer
      // flag, so there is nothing to read back off the response: this path
      // is only reachable with Enterprise credentials against the
      // production host (the self-service sandbox was decommissioned - see
      // README), so a successful answer here is live inventory.
      _lastDataMode = FlightDataMode.live;
      return FlightQuote(
        priceEur: cheapest.totalPrice,
        departure: cheapest.departure,
        arrival: cheapest.arrival,
        carrier: cheapest.carrierName,
      );
    } catch (error) {
      debugPrint('AmadeusFlightPriceSource: falling back to mock data ($error).');
      return _fallback(origin, destination, date);
    }
  }
}
