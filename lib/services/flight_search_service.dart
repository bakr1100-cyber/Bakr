import 'dart:math';

import '../models/airport.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../models/trip_leg.dart';

/// Mocked "Smart Flight Engine".
///
/// This is deliberately NOT wired to a real GDS/flight API - there is no
/// production flight/train data source configured for this build. Instead
/// it deterministically synthesizes a realistic-looking set of options
/// (direct, alternative departure airport, alternative destination airport
/// + onward train, stopover, and multimodal flight+train+bus combinations)
/// so the whole product experience - search, compare, budget mode, and the
/// explanatory copy the AI gives - can be built, demoed and tested end to
/// end. Swap the body of [search] for calls to a real flight aggregator
/// (e.g. Amadeus, Kiwi Tequila, Duffel) plus ONCF/rail timetable APIs to go
/// to production; the [Itinerary]/[TripLeg] models are shaped to hold real
/// data unchanged.
class FlightSearchService {
  Future<List<Itinerary>> search(TravelIntent intent) async {
    final origin = intent.origin;
    final destination = intent.destination;
    if (origin == null || destination == null) return [];

    final date = intent.departureDate ?? DateTime.now().add(const Duration(days: 7));
    final passengers = intent.passengerCount ?? 1;

    final candidates = <Itinerary>[
      _direct(origin, destination, date, passengers),
      ..._alternativeDeparture(origin, destination, date, passengers),
      ..._alternativeDestinationWithTrain(origin, destination, date, passengers),
      ..._stopover(origin, destination, date, passengers),
      ..._multimodal(origin, destination, date, passengers),
    ];

    candidates.sort((a, b) => a.totalPriceEur.compareTo(b.totalPriceEur));

    if (intent.maxBudgetEur != null) {
      final withinBudget =
          candidates.where((c) => c.totalPriceEur <= intent.maxBudgetEur!).toList();
      // Budget mode: "Die KI sucht solange weiter, bis sie passende
      // Möglichkeiten findet." If nothing fits yet, always surface the
      // cheapest option found so the user is never left empty-handed.
      return withinBudget.isNotEmpty ? withinBudget : [candidates.first];
    }

    if (intent.avoidLongLayover) {
      candidates.removeWhere(
        (c) => c.totalLayoverTime > const Duration(hours: 3) && !c.isDirect,
      );
    }

    return candidates;
  }

  // --- Pricing model -------------------------------------------------

  // Deterministic (pure) function of the airport pair only, so repeated
  // searches for the same route return stable, reproducible prices instead
  // of drifting on every call.
  double _basePrice(Airport a, Airport b) {
    final seed = (a.code + b.code).codeUnits.fold<int>(0, (s, c) => s + c);
    final variance = Random(seed).nextInt(40);
    return 180 + (seed % 220).toDouble() + variance;
  }

  double _perPassenger(double price, int passengers) => price * passengers;

  // --- Candidate generators -------------------------------------------

  Itinerary _direct(Airport origin, Airport destination, DateTime date, int pax) {
    final price = _perPassenger(_basePrice(origin, destination), pax);
    return Itinerary(
      id: 'direct-${origin.code}-${destination.code}',
      legs: [
        TripLeg(
          mode: LegMode.flight,
          from: origin,
          to: destination,
          departure: date,
          arrival: date.add(const Duration(hours: 4)),
          priceEur: price,
          carrier: _carrierFor(origin, destination),
        ),
      ],
      explanation:
          'Direktflug von ${origin.city} nach ${destination.city}.',
    );
  }

  // The alternative options below are deliberately priced as a fraction of
  // the direct route's own base price (rather than by independently
  // pricing e.g. Frankfurt->Rabat) so that "the smart engine always finds
  // something cheaper" holds by construction for every origin/destination
  // pair, matching the product brief, instead of depending on how two
  // unrelated city-pairs' prices happen to compare.
  List<Itinerary> _alternativeDeparture(
      Airport origin, Airport destination, DateTime date, int pax) {
    final directBase = _basePrice(origin, destination);
    final nearby = europeanAirports
        .where((a) => a.country == origin.country && a.code != origin.code)
        .take(2);

    return nearby.map((alt) {
      final altSeed = alt.code.codeUnits.fold<int>(0, (s, c) => s + c);
      final discount = 0.80 + (altSeed % 10) / 100; // 0.80-0.89, always < 1
      final price = _perPassenger(directBase * discount, pax);
      final saved = _perPassenger(directBase, pax) - price;
      return Itinerary(
        id: 'altdep-${alt.code}-${destination.code}',
        legs: [
          TripLeg(
            mode: LegMode.flight,
            from: alt,
            to: destination,
            departure: date,
            arrival: date.add(const Duration(hours: 4)),
            priceEur: price,
            carrier: _carrierFor(alt, destination),
          ),
        ],
        explanation:
            'Ab ${alt.city} statt ${origin.city} sparst du ${saved.toStringAsFixed(0)} €.',
      );
    }).toList();
  }

  List<Itinerary> _alternativeDestinationWithTrain(
      Airport origin, Airport destination, DateTime date, int pax) {
    if (destination.code == 'CMN' || destination.code == 'RBA') return [];

    // Fly into a cheaper Moroccan hub, then take the train onward - the
    // canonical example from the product brief: fly to Rabat, train to Fès.
    const hub = Airport(code: 'RBA', city: 'Rabat', country: 'Marokko');
    final directBase = _basePrice(origin, destination);
    final flightPrice = _perPassenger(directBase * 0.6, pax);
    final trainPrice = _perPassenger(18, pax);
    final total = flightPrice + trainPrice;
    final directPrice = _perPassenger(directBase, pax);
    final saved = directPrice - total;
    if (saved <= 0) return [];

    final flightArrival = date.add(const Duration(hours: 4));
    final trainDeparture = flightArrival.add(const Duration(hours: 1));

    return [
      Itinerary(
        id: 'althub-${hub.code}-${destination.code}',
        legs: [
          TripLeg(
            mode: LegMode.flight,
            from: origin,
            to: hub,
            departure: date,
            arrival: flightArrival,
            priceEur: flightPrice,
            carrier: _carrierFor(origin, hub),
          ),
          TripLeg(
            mode: LegMode.train,
            from: hub,
            to: destination,
            departure: trainDeparture,
            arrival: trainDeparture.add(const Duration(hours: 2, minutes: 50)),
            priceEur: trainPrice,
            carrier: 'ONCF',
          ),
        ],
        explanation:
            'Von ${hub.city} nach ${destination.city} fährt ein ONCF-Zug. '
            'Dadurch sparst du ${saved.toStringAsFixed(0)} €.',
      ),
    ];
  }

  List<Itinerary> _stopover(
      Airport origin, Airport destination, DateTime date, int pax) {
    const stopoverCities = [
      Airport(code: 'MAD', city: 'Madrid', country: 'Spanien'),
      Airport(code: 'BCN', city: 'Barcelona', country: 'Spanien'),
      Airport(code: 'CDG', city: 'Paris', country: 'Frankreich'),
      Airport(code: 'LIS', city: 'Lissabon', country: 'Portugal'),
      Airport(code: 'CMN', city: 'Casablanca', country: 'Marokko'),
    ];

    final via = stopoverCities.firstWhere(
      (a) => a.code != origin.code && a.code != destination.code,
      orElse: () => stopoverCities.first,
    );

    final directBase = _basePrice(origin, destination);
    final leg1Price = _perPassenger(directBase * 0.45, pax);
    final leg2Price = _perPassenger(directBase * 0.40, pax);
    final total = leg1Price + leg2Price;
    final directPrice = _perPassenger(directBase, pax);
    final saved = directPrice - total;
    if (saved <= 0) return [];

    final leg1Arrival = date.add(const Duration(hours: 2, minutes: 30));
    final leg2Departure = leg1Arrival.add(const Duration(hours: 2));

    return [
      Itinerary(
        id: 'stopover-${via.code}',
        legs: [
          TripLeg(
            mode: LegMode.flight,
            from: origin,
            to: via,
            departure: date,
            arrival: leg1Arrival,
            priceEur: leg1Price,
            carrier: _carrierFor(origin, via),
          ),
          TripLeg(
            mode: LegMode.flight,
            from: via,
            to: destination,
            departure: leg2Departure,
            arrival: leg2Departure.add(const Duration(hours: 2, minutes: 15)),
            priceEur: leg2Price,
            carrier: _carrierFor(via, destination),
          ),
        ],
        explanation:
            'Mit einem Zwischenstopp in ${via.city} sparst du '
            '${saved.toStringAsFixed(0)} €.',
        riskLevel: RiskLevel.medium,
      ),
    ];
  }

  List<Itinerary> _multimodal(
      Airport origin, Airport destination, DateTime date, int pax) {
    if (origin.country != 'Deutschland') return [];

    const frankfurt = Airport(code: 'FRA', city: 'Frankfurt', country: 'Deutschland');
    const rabat = Airport(code: 'RBA', city: 'Rabat', country: 'Marokko');

    final directBase = _basePrice(origin, destination);
    final trainPrice = _perPassenger(35, pax);
    final trainArrival = date.subtract(const Duration(hours: 2));
    final flightDeparture = date;
    final flightPrice = _perPassenger(directBase * 0.5, pax);
    final flightArrival = flightDeparture.add(const Duration(hours: 4));
    final onwardTrainDeparture = flightArrival.add(const Duration(hours: 1));
    final onwardTrainPrice = _perPassenger(18, pax);

    final legs = <TripLeg>[
      TripLeg(
        mode: LegMode.train,
        from: origin,
        to: frankfurt,
        departure: trainArrival.subtract(const Duration(hours: 1, minutes: 15)),
        arrival: trainArrival,
        priceEur: trainPrice,
        carrier: 'ICE',
      ),
      TripLeg(
        mode: LegMode.flight,
        from: frankfurt,
        to: rabat,
        departure: flightDeparture,
        arrival: flightArrival,
        priceEur: flightPrice,
        carrier: _carrierFor(frankfurt, rabat),
      ),
    ];

    if (destination.code != rabat.code) {
      legs.add(
        TripLeg(
          mode: LegMode.train,
          from: rabat,
          to: destination,
          departure: onwardTrainDeparture,
          arrival: onwardTrainDeparture.add(const Duration(hours: 2, minutes: 50)),
          priceEur: onwardTrainPrice,
          carrier: 'ONCF',
        ),
      );
    }

    final total = legs.fold<double>(0, (s, l) => s + l.priceEur);
    final directPrice = _perPassenger(directBase, pax);
    final saved = directPrice - total;
    if (saved <= 0) return [];

    return [
      Itinerary(
        id: 'multimodal-${origin.code}-${destination.code}',
        legs: legs,
        explanation:
            'ICE nach Frankfurt, Flug nach Rabat, Zug weiter nach '
            '${destination.city}. Gesamtpreis ${total.toStringAsFixed(0)} €, '
            'du sparst ${saved.toStringAsFixed(0)} € gegenüber dem Direktflug.',
      ),
    ];
  }

  String _carrierFor(Airport a, Airport b) {
    const carriers = ['Royal Air Maroc', 'Ryanair', 'Air Arabia', 'Transavia', 'Vueling'];
    final seed = (a.code + b.code).codeUnits.fold<int>(0, (s, c) => s + c);
    return carriers[seed % carriers.length];
  }
}
