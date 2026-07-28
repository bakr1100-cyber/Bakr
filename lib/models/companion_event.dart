/// A single travel-companion update surfaced before/during/after the trip -
/// gate changes, boarding calls, delays, ONCF connections, check-in
/// reminders, etc.
class CompanionEvent {
  const CompanionEvent({
    required this.id,
    required this.stage,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isUrgent = false,
  });

  final String id;
  final CompanionStage stage;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isUrgent;
}

enum CompanionStage { beforeTrip, atAirport, duringFlight, afterLanding }
