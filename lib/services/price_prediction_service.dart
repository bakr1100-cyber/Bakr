import 'dart:math';

import '../core/localization/app_localizations.dart';

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
    required AppLanguage language,
  }) {
    final daysUntilDeparture = departureDate.difference(DateTime.now()).inDays;
    final volatility = _random.nextDouble();

    if (daysUntilDeparture > 45 && volatility < 0.6) {
      return PricePrediction(
        trend: PriceTrend.likelyToDrop,
        message: switch (language) {
          AppLanguage.de => 'Warte noch ein paar Tage, der Preis fällt bei diesem Vorlauf meist noch.',
          AppLanguage.fr =>
            'Attends encore quelques jours, le prix a tendance à encore baisser avec ce délai.',
          AppLanguage.en => 'Wait a few more days - the price usually still drops this far out.',
          AppLanguage.ar => 'انتظر بضعة أيام أخرى، عادة ما ينخفض السعر مع هذه المهلة.',
          AppLanguage.ary => 'تسنى شي شوية ديال الأيام، الثمن كيهبط عادة مع هاد المدة.',
        },
        confidence: 0.62,
      );
    }
    if (daysUntilDeparture < 14) {
      return PricePrediction(
        trend: PriceTrend.likelyToRise,
        message: switch (language) {
          AppLanguage.de =>
            'Jetzt buchen. Der Preis wird bei so kurzer Vorlaufzeit wahrscheinlich steigen.',
          AppLanguage.fr =>
            'Réserve maintenant. Le prix va probablement augmenter avec un délai aussi court.',
          AppLanguage.en => 'Book now. The price will likely rise this close to departure.',
          AppLanguage.ar => 'احجز الآن. من المرجح أن يرتفع السعر مع هذه المهلة القصيرة.',
          AppLanguage.ary => 'حجز دابا. الثمن غادي يطلع مع هاد المدة القصيرة.',
        },
        confidence: 0.74,
      );
    }
    return PricePrediction(
      trend: PriceTrend.stable,
      message: switch (language) {
        AppLanguage.de => 'Der Preis ist aktuell stabil, du kannst in Ruhe vergleichen.',
        AppLanguage.fr => 'Le prix est actuellement stable, tu peux comparer tranquillement.',
        AppLanguage.en => 'The price is currently stable, so you can compare at your own pace.',
        AppLanguage.ar => 'السعر مستقر حاليًا، يمكنك المقارنة بهدوء.',
        AppLanguage.ary => 'الثمن مستقر دابا، تقدر تقارن على راحتك.',
      },
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
