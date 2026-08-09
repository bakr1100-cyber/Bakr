import 'airport.dart';

class PriceAlert {
  PriceAlert({
    required this.id,
    required this.origin,
    required this.destination,
    required this.watchedPriceEur,
    this.currentPriceEur,
  });

  final String id;
  final Airport origin;
  final Airport destination;
  final double watchedPriceEur;
  double? currentPriceEur;

  double? get dropEur =>
      currentPriceEur == null ? null : watchedPriceEur - currentPriceEur!;

  /// Airports are stored by code and looked back up against the fixed
  /// [europeanAirports]/[moroccanAirports] lists on the way back in, rather
  /// than serializing lat/lon/etc. themselves - keeps the stored shape
  /// small and always in sync with the airport data shipped in the app.
  Map<String, dynamic> toJson() => {
        'id': id,
        'originCode': origin.code,
        'destinationCode': destination.code,
        'watchedPriceEur': watchedPriceEur,
        'currentPriceEur': currentPriceEur,
      };

  /// Throws if the stored codes don't resolve to a known airport (e.g. the
  /// app's airport list changed) - callers should skip entries that fail to
  /// parse rather than lose the whole stored list over one bad entry.
  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    final origin = findAirportByCode(json['originCode'] as String?);
    final destination = findAirportByCode(json['destinationCode'] as String?);
    if (origin == null || destination == null) {
      throw FormatException('Unknown airport code in stored price alert: $json');
    }
    return PriceAlert(
      id: json['id'] as String,
      origin: origin,
      destination: destination,
      watchedPriceEur: (json['watchedPriceEur'] as num).toDouble(),
      currentPriceEur: (json['currentPriceEur'] as num?)?.toDouble(),
    );
  }
}
