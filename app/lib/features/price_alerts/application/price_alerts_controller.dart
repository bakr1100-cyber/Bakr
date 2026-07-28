import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/price_alert.dart';

/// In-memory watchlist. A real build persists alerts in Firestore and
/// triggers pushes from the `notifications` Cloud Function when
/// `priceTracking` observes `currentPrice <= maxPrice`.
class PriceAlertsController extends Notifier<List<PriceAlert>> {
  @override
  List<PriceAlert> build() => [
        const PriceAlert(
          id: 'seed-1',
          origin: 'Düsseldorf',
          destination: 'Fès',
          maxPrice: 200,
          currentPrice: 148,
          currency: 'EUR',
        ),
      ];

  void addAlert({
    required String origin,
    required String destination,
    required double maxPrice,
  }) {
    state = [
      ...state,
      PriceAlert(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        origin: origin,
        destination: destination,
        maxPrice: maxPrice,
        currentPrice: maxPrice,
        currency: 'EUR',
      ),
    ];
  }

  void removeAlert(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

final priceAlertsControllerProvider =
    NotifierProvider<PriceAlertsController, List<PriceAlert>>(
  PriceAlertsController.new,
);
