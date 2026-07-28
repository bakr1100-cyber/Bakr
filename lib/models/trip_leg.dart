import 'airport.dart';

enum LegMode { flight, train, bus, taxi }

extension LegModeLabel on LegMode {
  String get label => switch (this) {
        LegMode.flight => 'Flug',
        LegMode.train => 'Zug',
        LegMode.bus => 'Bus',
        LegMode.taxi => 'Taxi',
      };
}

/// One segment of a journey - a single flight, a train ride (ICE/TGV/ONCF),
/// a bus, or a taxi transfer. An [Itinerary] is a chain of these.
class TripLeg {
  const TripLeg({
    required this.mode,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.priceEur,
    this.carrier,
    this.flightNumber,
  });

  final LegMode mode;
  final Airport from;
  final Airport to;
  final DateTime departure;
  final DateTime arrival;
  final double priceEur;
  final String? carrier;
  final String? flightNumber;

  Duration get duration => arrival.difference(departure);
}
