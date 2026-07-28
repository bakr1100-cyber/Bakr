/// The 4 inputs the user provides up front: origin, destination, date,
/// passenger count. Everything else (alternate airports, stopovers,
/// multimodal legs, budget constraints extracted from chat) is inferred by
/// the AI/flight engine, not asked of the user directly.
class SearchQuery {
  const SearchQuery({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.passengers = 1,
    this.maxBudget,
  });

  final String origin;
  final String destination;
  final DateTime departureDate;
  final int passengers;

  /// Optional budget ceiling, e.g. extracted from "Ich möchte maximal 180 €
  /// bezahlen" in the AI chat.
  final double? maxBudget;

  SearchQuery copyWith({
    String? origin,
    String? destination,
    DateTime? departureDate,
    int? passengers,
    double? maxBudget,
  }) {
    return SearchQuery(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      passengers: passengers ?? this.passengers,
      maxBudget: maxBudget ?? this.maxBudget,
    );
  }
}
