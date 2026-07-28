/// Learned/stored preferences per the "Persönliche Empfehlungen" feature:
/// favorite airports, favorite airlines, typical travel times, budget, and
/// whether the user usually travels solo or with family.
class UserPreferences {
  UserPreferences({
    this.favoriteOriginAirportCode,
    this.favoriteDestinationAirportCode,
    this.favoriteAirlines = const [],
    this.usualMaxBudgetEur,
    this.travelsWithFamily = false,
    this.preferredVoiceIsFemale = true,
  });

  final String? favoriteOriginAirportCode;
  final String? favoriteDestinationAirportCode;
  final List<String> favoriteAirlines;
  final double? usualMaxBudgetEur;
  final bool travelsWithFamily;
  final bool preferredVoiceIsFemale;

  UserPreferences copyWith({
    String? favoriteOriginAirportCode,
    String? favoriteDestinationAirportCode,
    List<String>? favoriteAirlines,
    double? usualMaxBudgetEur,
    bool? travelsWithFamily,
    bool? preferredVoiceIsFemale,
  }) {
    return UserPreferences(
      favoriteOriginAirportCode:
          favoriteOriginAirportCode ?? this.favoriteOriginAirportCode,
      favoriteDestinationAirportCode: favoriteDestinationAirportCode ??
          this.favoriteDestinationAirportCode,
      favoriteAirlines: favoriteAirlines ?? this.favoriteAirlines,
      usualMaxBudgetEur: usualMaxBudgetEur ?? this.usualMaxBudgetEur,
      travelsWithFamily: travelsWithFamily ?? this.travelsWithFamily,
      preferredVoiceIsFemale:
          preferredVoiceIsFemale ?? this.preferredVoiceIsFemale,
    );
  }

  Map<String, dynamic> toJson() => {
        'favoriteOriginAirportCode': favoriteOriginAirportCode,
        'favoriteDestinationAirportCode': favoriteDestinationAirportCode,
        'favoriteAirlines': favoriteAirlines,
        'usualMaxBudgetEur': usualMaxBudgetEur,
        'travelsWithFamily': travelsWithFamily,
        'preferredVoiceIsFemale': preferredVoiceIsFemale,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      favoriteOriginAirportCode: json['favoriteOriginAirportCode'] as String?,
      favoriteDestinationAirportCode:
          json['favoriteDestinationAirportCode'] as String?,
      favoriteAirlines: (json['favoriteAirlines'] as List?)?.cast<String>() ??
          const [],
      usualMaxBudgetEur: (json['usualMaxBudgetEur'] as num?)?.toDouble(),
      travelsWithFamily: json['travelsWithFamily'] as bool? ?? false,
      preferredVoiceIsFemale: json['preferredVoiceIsFemale'] as bool? ?? true,
    );
  }
}
