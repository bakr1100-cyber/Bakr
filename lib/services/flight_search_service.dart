import 'dart:math' as math;

import '../core/localization/app_localizations.dart';
import '../models/airport.dart';
import '../models/itinerary.dart';
import '../models/travel_intent.dart';
import '../models/trip_leg.dart';
import 'flight_price_source.dart';
import 'geo.dart';
import 'mock_flight_price_source.dart';

/// How far from the requested departure airport we'll look for a genuinely
/// nearby alternative (e.g. Düsseldorf/Cologne/Frankfurt are all realistic
/// substitutes for each other for someone in the Rhineland/Ruhr area).
const _nearbyDepartureRadiusKm = 220.0;

/// How far from the requested Moroccan destination we'll look for a nearby
/// alternative airport worth a ground transfer - tuned to comfortably
/// catch Casablanca<->Rabat (~90 km) while excluding pairs that aren't a
/// realistic swap (Fès is ~200 km from Casablanca).
const _nearbyDestinationRadiusKm = 120.0;

/// An "alternative" only earns the label if it actually saves a
/// noticeable amount - the larger of a flat floor and a percentage of the
/// direct price, so a €400 route needs to save more than a €80 one does
/// to count. Without this, a handful of euros of noise (e.g. two nearby
/// airports pricing a few euros apart) showed up as a whole extra
/// "alternative" that wasn't meaningfully better than just booking direct.
const _minMeaningfulSavingsEur = 15.0;
const _minMeaningfulSavingsFraction = 0.05;

/// However many genuinely-better alternatives exist, only the best ones
/// are worth showing - past this many, more options stop helping the
/// user decide and start being noise. Ranked by [_alternativeValueScore],
/// not just price, before capping.
const _maxAlternativesShown = 5;

/// Assumed value of the traveler's own time, used only to rank
/// alternatives against each other (an alternative that saves €20 but
/// costs 3 extra hours should rank below one that saves €15 for 20 extra
/// minutes) - not shown to the user, not used to filter anything out.
const _timeValueEurPerHour = 8.0;

bool _isMeaningfulSaving(double directTotal, double alternativeTotal) {
  final savings = directTotal - alternativeTotal;
  final bar = math.max(_minMeaningfulSavingsEur, directTotal * _minMeaningfulSavingsFraction);
  return savings >= bar;
}

double _alternativeValueScore(Itinerary itinerary) {
  final savings = itinerary.savingsEur ?? 0;
  final extraHours = (itinerary.extraTravelTime ?? Duration.zero).inMinutes / 60;
  return savings - extraHours * _timeValueEurPerHour;
}

/// The "Smart Flight Engine": generates and prices normal flight
/// connections (direct + a real layover via Casablanca - [ResultTier.
/// standard]) alongside creative alternative-departure/destination-airport,
/// stopover, and flight+train multimodal itineraries ([ResultTier.
/// alternative]), the latter only ever surfaced when actually cheaper than
/// the direct route. The UI shows standard results first and keeps
/// alternatives collapsed until the user asks for more options.
///
/// Every individual flight leg is priced through a [FlightPriceSource] -
/// [MockFlightPriceSource] by default (deterministic synthetic data), or
/// a real source such as `AmadeusFlightPriceSource` when configured (see
/// `app.dart`). Train/bus legs (ICE, ONCF) are always synthetic fixed
/// prices - there is no rail API wired into this build - so those numbers
/// are illustrative, not real fares.
class FlightSearchService {
  FlightSearchService({FlightPriceSource? priceSource})
      : _priceSource = priceSource ?? MockFlightPriceSource();

  final FlightPriceSource _priceSource;

  /// What the prices in the most recent [search] actually were - real live
  /// inventory, a test/sandbox environment, or synthetic mock data. Null
  /// before the first search. Surfaced to the user on the results screen,
  /// since a sandbox answer looks identical to a real one otherwise.
  FlightDataMode? get lastDataMode => _priceSource.lastDataMode;

  Future<List<Itinerary>> search(
    TravelIntent intent, {
    AppLanguage language = AppLanguage.de,
  }) async {
    final origin = intent.origin;
    final destination = intent.destination;
    if (origin == null || destination == null) return [];

    final date = intent.departureDate ?? DateTime.now().add(const Duration(days: 7));
    final passengers = intent.passengerCount ?? 1;

    final directQuote =
        await _priceSource.quoteDirect(origin: origin, destination: destination, date: date);
    if (directQuote == null) return [];

    final directTotal = directQuote.priceEur * passengers;
    final directItinerary =
        _toDirectItinerary(origin, destination, directQuote, passengers, language);
    final directDuration = directItinerary.totalDuration;

    final results = await Future.wait([
      _standardConnection(origin, destination, date, passengers, language),
      _alternativeDeparture(
          origin, destination, date, passengers, directTotal, directDuration, language),
      _alternativeDestinationWithTrain(
          origin, destination, date, passengers, directTotal, directDuration, language),
      _nearbyDestinationAirport(
          origin, destination, date, passengers, directTotal, directDuration, language),
      _stopover(origin, destination, date, passengers, directTotal, directDuration, language),
      _multimodal(origin, destination, date, passengers, directTotal, directDuration, language),
    ]);

    final standardTier = <Itinerary>[directItinerary, ...results.first];
    final alternativeTier = <Itinerary>[for (final group in results.skip(1)) ...group]
      ..sort((a, b) => _alternativeValueScore(b).compareTo(_alternativeValueScore(a)));

    final candidates = <Itinerary>[
      ...standardTier,
      ...alternativeTier.take(_maxAlternativesShown),
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
    AppLanguage language,
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
      explanation: _explainDirect(language, origin.city, destination.city),
      tier: ResultTier.standard,
    );
  }

  /// A normal flight connection with a real layover through Morocco's
  /// biggest hub, Casablanca - the kind of "1 Umstieg" option a real flight
  /// search returns alongside the direct flight, not a creative AI
  /// suggestion. Always included (when a quote succeeds) regardless of
  /// whether it beats the direct price, since standard results are just
  /// sorted by price rather than filtered for savings.
  Future<List<Itinerary>> _standardConnection(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    AppLanguage language,
  ) async {
    const casablanca = Airport(code: 'CMN', city: 'Casablanca', country: 'Marokko');
    if (origin.code == casablanca.code || destination.code == casablanca.code) {
      return [];
    }

    final leg1Quote =
        await _priceSource.quoteDirect(origin: origin, destination: casablanca, date: date);
    if (leg1Quote == null) return [];

    final leg2Departure = leg1Quote.arrival.add(const Duration(hours: 2));
    final leg2Quote = await _priceSource.quoteDirect(
        origin: casablanca, destination: destination, date: leg2Departure);
    if (leg2Quote == null) return [];

    final leg1Price = leg1Quote.priceEur * pax;
    final leg2Price = leg2Quote.priceEur * pax;

    return [
      Itinerary(
        id: 'connect-${casablanca.code}-${destination.code}',
        tier: ResultTier.standard,
        legs: [
          TripLeg(
            mode: LegMode.flight,
            from: origin,
            to: casablanca,
            departure: leg1Quote.departure,
            arrival: leg1Quote.arrival,
            priceEur: leg1Price,
            carrier: leg1Quote.carrier,
          ),
          TripLeg(
            mode: LegMode.flight,
            from: casablanca,
            to: destination,
            departure: leg2Quote.departure,
            arrival: leg2Quote.arrival,
            priceEur: leg2Price,
            carrier: leg2Quote.carrier,
          ),
        ],
        explanation: _explainConnection(language, casablanca.city),
        riskLevel: RiskLevel.medium,
      ),
    ];
  }

  Future<List<Itinerary>> _alternativeDeparture(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    double directTotal,
    Duration directDuration,
    AppLanguage language,
  ) async {
    // Real nearby-airport search instead of a "same country" guess - e.g.
    // for someone departing from Frankfurt, Düsseldorf/Cologne/Dortmund are
    // genuine regional alternatives (~150-220 km), while Madrid (also
    // "Europe") obviously isn't.
    final nearby = nearbyAirports(origin, europeanAirports, radiusKm: _nearbyDepartureRadiusKm);

    final itineraries = <Itinerary>[];
    for (final alt in nearby) {
      final quote =
          await _priceSource.quoteDirect(origin: alt, destination: destination, date: date);
      if (quote == null) continue;

      final total = quote.priceEur * pax;
      if (!_isMeaningfulSaving(directTotal, total)) continue;

      final duration = quote.arrival.difference(quote.departure);
      final km = distanceKm(origin, alt);
      itineraries.add(
        Itinerary(
          id: 'altdep-${alt.code}-${destination.code}',
          tier: ResultTier.alternative,
          savingsEur: directTotal - total,
          extraTravelTime: duration > directDuration ? duration - directDuration : Duration.zero,
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
          explanation: _explainAlternativeDeparture(
              language, alt.city, km.round(), origin.city, directTotal - total),
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
    Duration directDuration,
    AppLanguage language,
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
    if (!_isMeaningfulSaving(directTotal, total)) return [];

    final trainDeparture = quote.arrival.add(const Duration(hours: 1));
    final trainArrival = trainDeparture.add(const Duration(hours: 2, minutes: 50));
    final saved = directTotal - total;
    final duration = trainArrival.difference(quote.departure);

    return [
      Itinerary(
        id: 'althub-${hub.code}-${destination.code}',
        tier: ResultTier.alternative,
        savingsEur: saved,
        extraTravelTime: duration > directDuration ? duration - directDuration : Duration.zero,
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
            arrival: trainArrival,
            priceEur: trainPrice,
            carrier: 'ONCF',
          ),
        ],
        explanation: _explainAltDestinationTrain(language, hub.city, destination.city, saved),
      ),
    ];
  }

  /// Nearby-airport swap on the *destination* side, using real distance
  /// instead of a single hardcoded hub - fixes the gap where searching to
  /// Rabat never suggested Casablanca (only ~90 km away) just because Rabat
  /// itself was already the special-cased hub. Symmetric: also works the
  /// other way (destination Casablanca -> suggests landing in Rabat).
  Future<List<Itinerary>> _nearbyDestinationAirport(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    double directTotal,
    Duration directDuration,
    AppLanguage language,
  ) async {
    final nearby =
        nearbyAirports(destination, moroccanAirports, radiusKm: _nearbyDestinationRadiusKm);

    final itineraries = <Itinerary>[];
    for (final alt in nearby) {
      final quote = await _priceSource.quoteDirect(origin: origin, destination: alt, date: date);
      if (quote == null) continue;

      final flightPrice = quote.priceEur * pax;
      final km = distanceKm(alt, destination);
      final transferPrice = groundTransferPriceEur(km) * pax;
      final transferDuration = groundTransferDuration(km);
      final total = flightPrice + transferPrice;
      if (!_isMeaningfulSaving(directTotal, total)) continue;

      final transferDeparture = quote.arrival.add(const Duration(minutes: 30));
      final transferArrival = transferDeparture.add(transferDuration);
      final duration = transferArrival.difference(quote.departure);
      final saved = directTotal - total;

      itineraries.add(
        Itinerary(
          id: 'altdest-${alt.code}-${destination.code}',
          tier: ResultTier.alternative,
          savingsEur: saved,
          extraTravelTime: duration > directDuration ? duration - directDuration : Duration.zero,
          legs: [
            TripLeg(
              mode: LegMode.flight,
              from: origin,
              to: alt,
              departure: quote.departure,
              arrival: quote.arrival,
              priceEur: flightPrice,
              carrier: quote.carrier,
            ),
            TripLeg(
              mode: LegMode.taxi,
              from: alt,
              to: destination,
              departure: transferDeparture,
              arrival: transferArrival,
              priceEur: transferPrice,
              carrier: 'Transfer',
            ),
          ],
          explanation: _explainAltDestinationAirport(
              language, alt.city, km.round(), destination.city, saved),
          riskLevel: RiskLevel.medium,
        ),
      );
    }
    return itineraries;
  }

  Future<List<Itinerary>> _stopover(
    Airport origin,
    Airport destination,
    DateTime date,
    int pax,
    double directTotal,
    Duration directDuration,
    AppLanguage language,
  ) async {
    // Creative alternative-airport routing - Casablanca is handled
    // separately as the standard-tier connection (see
    // [_standardConnection]), so this picks a genuinely sensible "other
    // airport" stopover: whichever European airport lies most directly on
    // the way from origin to destination (smallest detour vs. flying
    // direct), e.g. Málaga for many Germany->Morocco routes since it sits
    // right by the Gibraltar strait crossing.
    final candidates = europeanAirports
        .where((a) => a.code != origin.code && a.code != destination.code)
        .toList();
    if (candidates.isEmpty) return [];

    final directKm = distanceKm(origin, destination);
    candidates.sort((a, b) {
      final detourA = distanceKm(origin, a) + distanceKm(a, destination) - directKm;
      final detourB = distanceKm(origin, b) + distanceKm(b, destination) - directKm;
      return detourA.compareTo(detourB);
    });
    final via = candidates.first;

    final leg1Quote = await _priceSource.quoteDirect(origin: origin, destination: via, date: date);
    if (leg1Quote == null) return [];

    final leg2Departure = leg1Quote.arrival.add(const Duration(hours: 2));
    final leg2Quote =
        await _priceSource.quoteDirect(origin: via, destination: destination, date: leg2Departure);
    if (leg2Quote == null) return [];

    final leg1Price = leg1Quote.priceEur * pax;
    final leg2Price = leg2Quote.priceEur * pax;
    final total = leg1Price + leg2Price;
    if (!_isMeaningfulSaving(directTotal, total)) return [];

    final duration = leg2Quote.arrival.difference(leg1Quote.departure);

    return [
      Itinerary(
        id: 'stopover-${via.code}',
        tier: ResultTier.alternative,
        savingsEur: directTotal - total,
        extraTravelTime: duration > directDuration ? duration - directDuration : Duration.zero,
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
        explanation: _explainStopover(language, via.city, directTotal - total),
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
    Duration directDuration,
    AppLanguage language,
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
    if (!_isMeaningfulSaving(directTotal, total)) return [];

    final lastArrival = includesOnwardTrain
        ? onwardTrainDeparture.add(const Duration(hours: 2, minutes: 50))
        : flightQuote.arrival;
    final duration = lastArrival.difference(
        trainArrival.subtract(const Duration(hours: 1, minutes: 15)));

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
        tier: ResultTier.alternative,
        savingsEur: directTotal - total,
        extraTravelTime: duration > directDuration ? duration - directDuration : Duration.zero,
        legs: legs,
        explanation:
            _explainMultimodal(language, destination.city, total, directTotal - total),
      ),
    ];
  }

  static String _eur(double value) => value.toStringAsFixed(0);

  String _explainDirect(AppLanguage language, String origin, String destination) =>
      switch (language) {
        AppLanguage.de => 'Direktflug von $origin nach $destination.',
        AppLanguage.fr => 'Vol direct de $origin à $destination.',
        AppLanguage.en => 'Direct flight from $origin to $destination.',
        AppLanguage.ar => 'رحلة مباشرة من $origin إلى $destination.',
        AppLanguage.ary => 'طيران مباشر من $origin ل$destination.',
      };

  String _explainConnection(AppLanguage language, String viaCity) => switch (language) {
        AppLanguage.de => 'Verbindung über $viaCity (1 Umstieg).',
        AppLanguage.fr => 'Correspondance via $viaCity (1 escale).',
        AppLanguage.en => 'Connection via $viaCity (1 stop).',
        AppLanguage.ar => 'رحلة عبر $viaCity (توقف واحد).',
        AppLanguage.ary => 'طيران عبر $viaCity (وقفة وحدة).',
      };

  String _explainAlternativeDeparture(
    AppLanguage language,
    String altCity,
    int km,
    String originCity,
    double saved,
  ) {
    final amount = _eur(saved);
    return switch (language) {
      AppLanguage.de =>
        'Ab $altCity ($km km von $originCity) statt $originCity sparst du $amount €.',
      AppLanguage.fr =>
        'Au départ de $altCity ($km km de $originCity) au lieu de $originCity, tu économises $amount €.',
      AppLanguage.en =>
        'From $altCity ($km km from $originCity) instead of $originCity, you save €$amount.',
      AppLanguage.ar =>
        'من $altCity (على بعد $km كم من $originCity) بدلاً من $originCity، توفر $amount €.',
      AppLanguage.ary =>
        'من $altCity (كتبعد $km كم من $originCity) بدل $originCity، غادي توفر $amount €.',
    };
  }

  String _explainAltDestinationTrain(
    AppLanguage language,
    String hubCity,
    String destinationCity,
    double saved,
  ) {
    final amount = _eur(saved);
    return switch (language) {
      AppLanguage.de =>
        'Von $hubCity nach $destinationCity fährt ein ONCF-Zug. Dadurch sparst du $amount €.',
      AppLanguage.fr =>
        'Un train ONCF relie $hubCity à $destinationCity. Tu économises ainsi $amount €.',
      AppLanguage.en =>
        'An ONCF train runs from $hubCity to $destinationCity. This saves you €$amount.',
      AppLanguage.ar => 'يوجد قطار ONCF من $hubCity إلى $destinationCity. بذلك توفر $amount €.',
      AppLanguage.ary => 'كاين تران ONCF من $hubCity ل$destinationCity. بهاد الشي غادي توفر $amount €.',
    };
  }

  String _explainAltDestinationAirport(
    AppLanguage language,
    String altCity,
    int km,
    String destinationCity,
    double saved,
  ) {
    final amount = _eur(saved);
    return switch (language) {
      AppLanguage.de =>
        'Flug nach $altCity (nur $km km von $destinationCity entfernt) statt direkt nach '
            '$destinationCity, mit Transfer weiter. Dadurch sparst du $amount €.',
      AppLanguage.fr =>
        "Vol vers $altCity (à seulement $km km de $destinationCity) au lieu d'un vol direct vers "
            '$destinationCity, avec transfert ensuite. Tu économises ainsi $amount €.',
      AppLanguage.en =>
        'Flight to $altCity (only $km km from $destinationCity) instead of direct to '
            '$destinationCity, with a transfer onward. This saves you €$amount.',
      AppLanguage.ar =>
        'رحلة إلى $altCity (على بعد $km كم فقط من $destinationCity) بدلاً من رحلة مباشرة إلى '
            '$destinationCity، مع انتقال بعد ذلك. بذلك توفر $amount €.',
      AppLanguage.ary =>
        'طيران ل$altCity (غير $km كم من $destinationCity) بدل الطيران المباشر ل$destinationCity، '
            'وبعدها ترانسفير. غادي توفر $amount €.',
    };
  }

  String _explainStopover(AppLanguage language, String viaCity, double saved) {
    final amount = _eur(saved);
    return switch (language) {
      AppLanguage.de => 'Mit einem Zwischenstopp in $viaCity sparst du $amount €.',
      AppLanguage.fr => 'Avec une escale à $viaCity, tu économises $amount €.',
      AppLanguage.en => 'With a stopover in $viaCity, you save €$amount.',
      AppLanguage.ar => 'بتوقف في $viaCity، توفر $amount €.',
      AppLanguage.ary => 'بوقفة ف $viaCity، غادي توفر $amount €.',
    };
  }

  String _explainMultimodal(
    AppLanguage language,
    String destinationCity,
    double total,
    double saved,
  ) {
    final totalStr = _eur(total);
    final amount = _eur(saved);
    return switch (language) {
      AppLanguage.de =>
        'ICE nach Frankfurt, Flug nach Rabat, Zug weiter nach $destinationCity. Gesamtpreis '
            '$totalStr €, du sparst $amount € gegenüber dem Direktflug.',
      AppLanguage.fr =>
        "ICE jusqu'à Francfort, vol vers Rabat, puis train jusqu'à $destinationCity. Prix total "
            '$totalStr €, tu économises $amount € par rapport au vol direct.',
      AppLanguage.en =>
        'ICE train to Frankfurt, flight to Rabat, then train onward to $destinationCity. Total '
            'price €$totalStr, you save €$amount compared to the direct flight.',
      AppLanguage.ar =>
        'قطار ICE إلى فرانكفورت، رحلة إلى الرباط، ثم قطار إلى $destinationCity. السعر الإجمالي '
            '$totalStr €، توفر $amount € مقارنة بالرحلة المباشرة.',
      AppLanguage.ary =>
        'تران ICE لفرانكفورت، طيران للرباط، من بعد تران ل$destinationCity. الثمن الكامل $totalStr '
            '€، غادي توفر $amount € مقارنة بالطيران المباشر.',
    };
  }
}
