import 'airport.dart';

/// Structured intent extracted from a free-text / voice message by
/// [NluService]. Fields are nullable because the assistant fills them in
/// incrementally across a conversation ("Ich möchte nach Fès." -> later
/// "Mein Budget liegt bei 200 €.").
class TravelIntent {
  const TravelIntent({
    this.origin,
    this.destination,
    this.departureDate,
    this.passengerCount,
    this.maxBudgetEur,
    this.avoidLongLayover = false,
    this.travelingWithFamily = false,
    this.detectedLanguage,
    this.isLowConfidence = false,
  });

  final Airport? origin;
  final Airport? destination;
  final DateTime? departureDate;
  final int? passengerCount;
  final double? maxBudgetEur;
  final bool avoidLongLayover;
  final bool travelingWithFamily;
  final String? detectedLanguage;

  /// True when a city was matched via fuzzy fallback rather than an exact
  /// known alias, so the assistant should confirm before searching:
  /// "Ich bin mir nicht ganz sicher. Meintest du Düsseldorf nach Fès?"
  final bool isLowConfidence;

  bool get isSearchable => origin != null && destination != null;

  /// The single most important missing field, used to phrase the next
  /// clarifying question ("Möchtest du nach Casablanca oder Fès?").
  String? get nextMissingField {
    if (destination == null) return 'destination';
    if (origin == null) return 'origin';
    if (departureDate == null) return 'date';
    return null;
  }

  TravelIntent mergedWith(TravelIntent other) => TravelIntent(
        origin: other.origin ?? origin,
        destination: other.destination ?? destination,
        departureDate: other.departureDate ?? departureDate,
        passengerCount: other.passengerCount ?? passengerCount,
        maxBudgetEur: other.maxBudgetEur ?? maxBudgetEur,
        avoidLongLayover: other.avoidLongLayover || avoidLongLayover,
        travelingWithFamily: other.travelingWithFamily || travelingWithFamily,
        detectedLanguage: other.detectedLanguage ?? detectedLanguage,
        isLowConfidence: other.isLowConfidence,
      );

  TravelIntent copyWith({
    Airport? origin,
    Airport? destination,
    DateTime? departureDate,
    int? passengerCount,
    double? maxBudgetEur,
    bool? avoidLongLayover,
    bool? travelingWithFamily,
    String? detectedLanguage,
    bool? isLowConfidence,
  }) {
    return TravelIntent(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      passengerCount: passengerCount ?? this.passengerCount,
      maxBudgetEur: maxBudgetEur ?? this.maxBudgetEur,
      avoidLongLayover: avoidLongLayover ?? this.avoidLongLayover,
      travelingWithFamily: travelingWithFamily ?? this.travelingWithFamily,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      isLowConfidence: isLowConfidence ?? this.isLowConfidence,
    );
  }
}
