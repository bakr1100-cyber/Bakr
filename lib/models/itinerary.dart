import 'trip_leg.dart';

/// A complete, bookable route from origin to Morocco, possibly combining
/// several legs and modes of transport (flight + train + bus + taxi).
class Itinerary {
  const Itinerary({
    required this.id,
    required this.legs,
    required this.explanation,
    this.baggageIncluded = true,
    this.riskLevel = RiskLevel.low,
  });

  final String id;
  final List<TripLeg> legs;

  /// Human, friendly explanation of why this option was suggested and what
  /// it saves compared to the direct/obvious choice - e.g. "Von Rabat nach
  /// Fès fährt ein Zug. Dadurch sparst du 130 €."
  final String explanation;
  final bool baggageIncluded;
  final RiskLevel riskLevel;

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

enum RiskLevel { low, medium, high }

extension RiskLevelLabel on RiskLevel {
  String get label => switch (this) {
        RiskLevel.low => 'Geringes Risiko',
        RiskLevel.medium => 'Mittleres Risiko (getrennte Tickets)',
        RiskLevel.high => 'Hohes Risiko (kurze Umsteigezeit)',
      };
}
