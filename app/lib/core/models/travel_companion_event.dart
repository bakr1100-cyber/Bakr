/// The four phases of the trip the travel companion assists with, per the
/// product vision: before the trip, at the airport, during the flight, and
/// after landing.
enum TravelPhase { preFlight, atAirport, inFlight, postLanding }

class TravelCompanionEvent {
  const TravelCompanionEvent({
    required this.phase,
    required this.title,
    required this.description,
  });

  final TravelPhase phase;
  final String title;
  final String description;
}
