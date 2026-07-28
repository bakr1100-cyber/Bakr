import 'dart:math';

/// Predicts whether a price is likely to rise or fall. In production this
/// should be backed by a model trained on real historical fare data for the
/// route; here it derives a plausible, deterministic trend from the price
/// and the number of days until departure so the UI/copy can be built and
/// demoed against something.
class PricePredictionService {
  final _random = Random(7);

  PricePrediction predict({
    required double currentPriceEur,
    required DateTime departureDate,
  }) {
    final daysUntilDeparture = departureDate.difference(DateTime.now()).inDays;
    final volatility = _random.nextDouble();

    if (daysUntilDeparture > 45 && volatility < 0.6) {
      return PricePrediction(
        trend: PriceTrend.likelyToDrop,
        message: 'Warte noch ein paar Tage, der Preis fällt bei diesem Vorlauf meist noch.',
        confidence: 0.62,
      );
    }
    if (daysUntilDeparture < 14) {
      return const PricePrediction(
        trend: PriceTrend.likelyToRise,
        message: 'Jetzt buchen. Der Preis wird bei so kurzer Vorlaufzeit wahrscheinlich steigen.',
        confidence: 0.74,
      );
    }
    return const PricePrediction(
      trend: PriceTrend.stable,
      message: 'Der Preis ist aktuell stabil, du kannst in Ruhe vergleichen.',
      confidence: 0.55,
    );
  }
}

enum PriceTrend { likelyToDrop, likelyToRise, stable }

class PricePrediction {
  const PricePrediction({
    required this.trend,
    required this.message,
    required this.confidence,
  });

  final PriceTrend trend;
  final String message;
  final double confidence;
}
