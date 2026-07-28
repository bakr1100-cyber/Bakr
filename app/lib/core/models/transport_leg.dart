enum TransportMode { flight, train, bus, taxi }

/// A single leg of a journey, e.g. "ICE Düsseldorf -> Frankfurt" or
/// "Air Arabia Madrid -> Fès".
class TransportLeg {
  const TransportLeg({
    required this.mode,
    required this.carrier,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
  });

  final TransportMode mode;
  final String carrier;
  final String from;
  final String to;
  final DateTime departure;
  final DateTime arrival;

  Duration get duration => arrival.difference(departure);
}
