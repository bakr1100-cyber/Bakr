import '../models/airport.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../models/trip_leg.dart';
import 'flight_price_source.dart';
import 'mock_flight_price_source.dart';

/// The "Smart Flight Engine": generates and prices direct, alternative
/// departure/destination-airport, stopover, and flight+train multimodal
/// itineraries, only ever surfacing an alternative when it's actually
/// cheaper than the direct route.
///
/// Every individual flight leg is priced through a [FlightPriceSource] -
/// [MockFlightPriceSource] by default (deterministic synthetic data), or
/// a real source such as `DuffelFlightPriceSource` when configured (see
/// `app.dart`). Train/bus legs (ICE, ONCF) are always synthetic fixed
/// prices - there is no rail API wired into this build - so those numbers
/// are illustrative, not real fares.
class FlightSearchService {
  FlightSearchService({FlightPriceSource? priceSource})
      : _priceSource = priceSource ?? MockFlightPriceSource();

  final FlightPriceSource _priceSource;

  Future<List<Itinerary>> search(TravelIntent intent) async {
    final origin = intent.origin;
    final destination = intent.destination;
    if (origin == null || destination == null) return [];

    final date = intent.departureDate ?? DateTime.now().add(const Duration(days: 7));
    final passengers = intent.passengerCount ?? 1;

    final directQuote =
        await _priceSource.quoteDirect(origin: origin, destination: destination, date: date);
    if (directQuote == null) return [];

    final directTotal = directQuote.priceEur * passengers;

    final results = await Future.wait([
      _alternativeDeparture(origin, destination, date, passengers, directTotal),
      _alternativeDestinationWithTrain(origin, destination, date, passengers, directTotal),
      _stopover(origin, destination, date, passengers, directTotal),
      _multimodal(origin, destination, date, passengers, directTotal),
    ]);

    final candidates = <Itinerary>[
      _toDirectItinerary(origin, destination, directQuote, passengers),
      for (final group in results) ...group,
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

  Itinerary _toDirectItinerary(
    Airport origin,
    Airport destination,
    FlightQuote quote,
    int pax,
  ) {
    return Itinerary(
      id: 'direct-${origin.code}-${destination.code}',
      legs: [
        TripLeg(
          mode: LegMode.flight,
          from: origin,
          to: destination,
          departure: quote.departure,
          arrival: quote.arrival,
          priceEur: quote.priceEur * pax,
          carrier: quote.carrier,
        ),
      ],
      explanation: 'Direktflug von ${origin.city} nach ${destination.city}.',
    );
  }

  Future<List<Itinerary>> _alternativeDeparture(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    double directTotal,
  ) async {
    final nearby = europeanAirports
        .where((a) => a.country == origin.country && a.code != origin.code)
        .take(2);

    final itineraries = <Itinerary>[];
    for (final alt in nearby) {
      final quote =
          await _priceSource.quoteDirect(origin: alt, destination: destination, date: date);
      if (quote == null) continue;

      final total = quote.priceEur * pax;
      if (total >= directTotal) continue;

      itineraries.add(
        Itinerary(
          id: 'altdep-${alt.code}-${destination.code}',
          legs: [
            TripLeg(
              mode: LegMode.flight,
              from: alt,
              to: destination,
              departure: quote.departure,
              arrival: quote.arrival,
              priceEur: total,
              carrier: quote.carrier,
            ),
          ],
          explanation: 'Ab ${alt.city} statt ${origin.city} sparst du '
              '${(directTotal - total).toStringAsFixed(0)} €.',
        ),
      );
    }
    return itineraries;
  }

  Future<List<Itinerary>> _alternativeDestinationWithTrain(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    double directTotal,
  ) async {
    if (destination.code == 'CMN' || destination.code == 'RBA') return [];

    // Fly into a cheaper Moroccan hub, then take the train onward - the
    // canonical example from the product brief: fly to Rabat, train to Fès.
    const hub = Airport(code: 'RBA', city: 'Rabat', country: 'Marokko');
    final quote = await _priceSource.quoteDirect(origin: origin, destination: hub, date: date);
    if (quote == null) return [];

    final flightPrice = quote.priceEur * pax;
    final trainPrice = 18.0 * pax;
    final total = flightPrice + trainPrice;
    if (total >= directTotal) return [];

    final trainDeparture = quote.arrival.add(const Duration(hours: 1));
    final saved = directTotal - total;

    return [
      Itinerary(
        id: 'althub-${hub.code}-${destination.code}',
        legs: [
          TripLeg(
            mode: LegMode.flight,
            from: origin,
            to: hub,
            departure: quote.departure,
            arrival: quote.arrival,
            priceEur: flightPrice,
            carrier: quote.carrier,
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

  Future<List<Itinerary>> _stopover(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    double directTotal,
  ) async {
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

    final leg1Quote = await _priceSource.quoteDirect(origin: origin, destination: via, date: date);
    if (leg1Quote == null) return [];

    final leg2Departure = leg1Quote.arrival.add(const Duration(hours: 2));
    final leg2Quote =
        await _priceSource.quoteDirect(origin: via, destination: destination, date: leg2Departure);
    if (leg2Quote == null) return [];

    final leg1Price = leg1Quote.priceEur * pax;
    final leg2Price = leg2Quote.priceEur * pax;
    final total = leg1Price + leg2Price;
    if (total >= directTotal) return [];

    return [
      Itinerary(
        id: 'stopover-${via.code}',
        legs: [
          TripLeg(
            mode: LegMode.flight,
            from: origin,
            to: via,
            departure: leg1Quote.departure,
            arrival: leg1Quote.arrival,
            priceEur: leg1Price,
            carrier: leg1Quote.carrier,
          ),
          TripLeg(
            mode: LegMode.flight,
            from: via,
            to: destination,
            departure: leg2Quote.departure,
            arrival: leg2Quote.arrival,
            priceEur: leg2Price,
            carrier: leg2Quote.carrier,
          ),
        ],
        explanation: 'Mit einem Zwischenstopp in ${via.city} sparst du '
            '${(directTotal - total).toStringAsFixed(0)} €.',
        riskLevel: RiskLevel.medium,
      ),
    ];
  }

  Future<List<Itinerary>> _multimodal(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    double directTotal,
  ) async {
    if (origin.country != 'Deutschland') return [];

    const frankfurt = Airport(code: 'FRA', city: 'Frankfurt', country: 'Deutschland');
    const rabat = Airport(code: 'RBA', city: 'Rabat', country: 'Marokko');

    final flightQuote =
        await _priceSource.quoteDirect(origin: frankfurt, destination: rabat, date: date);
    if (flightQuote == null) return [];

    final trainPrice = 35.0 * pax;
    final trainArrival = flightQuote.departure.subtract(const Duration(hours: 2));
    final flightPrice = flightQuote.priceEur * pax;
    final onwardTrainDeparture = flightQuote.arrival.add(const Duration(hours: 1));
    final onwardTrainPrice = 18.0 * pax;
    final includesOnwardTrain = destination.code != rabat.code;

    final total = trainPrice + flightPrice + (includesOnwardTrain ? onwardTrainPrice : 0);
    if (total >= directTotal) return [];

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
        departure: flightQuote.departure,
        arrival: flightQuote.arrival,
        priceEur: flightPrice,
        carrier: flightQuote.carrier,
      ),
    ];

    if (includesOnwardTrain) {
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

    return [
      Itinerary(
        id: 'multimodal-${origin.code}-${destination.code}',
        legs: legs,
        explanation: 'ICE nach Frankfurt, Flug nach Rabat, Zug weiter nach '
            '${destination.city}. Gesamtpreis ${total.toStringAsFixed(0)} €, '
            'du sparst ${(directTotal - total).toStringAsFixed(0)} € gegenüber dem Direktflug.',
      ),
    ];
  }
}
