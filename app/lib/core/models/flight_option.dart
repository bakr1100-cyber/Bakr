import 'transport_leg.dart';

/// Why a given [FlightOption] was surfaced, mirroring the "smart" routes the
/// AI advisor proposes on top of the plain direct flight.
enum RouteStrategy {
  direct,
  alternateAirport,
  stopover,
  multimodal,
}

/// One ranked route/travel-plan candidate: could be a direct flight, a
/// flight from an alternate airport, a flight with a stopover, or a
/// flight+train+bus combination.
class FlightOption {
  const FlightOption({
    required this.id,
    required this.strategy,
    required this.legs,
    required this.totalPrice,
    required this.currency,
    required this.explanation,
    this.savingsVsCheapestDirect,
  });

  final String id;
  final RouteStrategy strategy;
  final List<TransportLeg> legs;
  final double totalPrice;
  final String currency;

  /// Human-readable explanation the AI advisor would give, e.g.
  /// "Von Rabat nach Fès fährt ein Zug. Dadurch sparst du 130 €."
  final String explanation;

  /// How much cheaper this is than the plain direct flight, if applicable.
  final double? savingsVsCheapestDirect;

  Duration get totalDuration {
    if (legs.isEmpty) return Duration.zero;
    return legs.last.arrival.difference(legs.first.departure);
  }

  String get origin => legs.first.from;
  String get destination => legs.last.to;
}
