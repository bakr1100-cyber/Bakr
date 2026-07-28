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
}
