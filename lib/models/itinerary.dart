import 'trip_leg.dart';

/// A complete, bookable route from origin to Morocco, possibly combining
/// several legs and modes of transport (flight + train + bus + taxi).
class Itinerary {
  const Itinerary({
    required this.id,
    required this.legs,
    required this.explanation,
    required this.tier,
    this.baggageIncluded = true,
    this.riskLevel = RiskLevel.low,
    this.savingsEur,
    this.extraTravelTime,
  });

  final String id;
  final List<TripLeg> legs;

  /// Human, friendly explanation of why this option was suggested and what
  /// it saves compared to the direct/obvious choice - e.g. "Von Rabat nach
  /// Fès fährt ein Zug. Dadurch sparst du 130 €."
  final String explanation;
  final bool baggageIncluded;
  final RiskLevel riskLevel;

  /// Whether this is a normal flight connection (direct or with a real
  /// layover) or a creative, AI-assembled alternative (different airport,
  /// flight+train/bus, multi-airline). Standard results are shown to the
  /// user immediately; alternatives only appear after they ask for more
  /// options - see "Flugsuche – Reihenfolge der Suchergebnisse".
  final ResultTier tier;

  /// How much cheaper this is than the direct flight, in euros. Only set
  /// on [ResultTier.alternative] itineraries, where it's shown alongside
  /// [extraTravelTime] so the user can weigh the trade-off at a glance.
  final double? savingsEur;

  /// How much longer this takes than the direct flight. Only set on
  /// [ResultTier.alternative] itineraries; `Duration.zero` if this
  /// alternative is not actually slower.
  final Duration? extraTravelTime;

  double get totalPriceEur =>
      legs.fold(0, (sum, leg) => sum + leg.priceEur);

  DateTime get departureTime => legs.first.departure;
  DateTime get arrivalTime => legs.last.arrival;

  Duration get totalDuration => arrivalTime.difference(departureTime);

  Duration get totalLayoverTime {
    var layover = Duration.zero;
    for (var i = 0; i < legs.length - 1; i++) {
      layover += legs[i + 1].departure.difference(legs[i].arrival);
    }
    return layover;
  }

  bool get isDirect => legs.length == 1;
  bool get isMultimodal => legs.map((l) => l.mode).toSet().length > 1;
}

/// See [Itinerary.tier].
enum ResultTier { standard, alternative }

enum RiskLevel { low, medium, high }
