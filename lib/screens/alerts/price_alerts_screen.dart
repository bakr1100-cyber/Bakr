import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/price_alerts_provider.dart';

class PriceAlertsScreen extends StatelessWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceAlertsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preisalarme'),
        actions: [
          IconButton(
            tooltip: 'Auf Preisänderungen prüfen',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: provider.checkForDrops,
          ),
        ],
      ),
      body: provider.alerts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aktiviere bei einer Reise "Preis beobachten", und ich '
                  'melde mich, sobald sie günstiger wird.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final alert in provider.alerts)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        '${alert.origin.city} → ${alert.destination.city}',
                      ),
                      subtitle: Text(
                        alert.dropEur != null && alert.dropEur! > 0
                            ? 'Jetzt ${alert.currentPriceEur!.toStringAsFixed(0)} € '
                                '(${alert.dropEur!.toStringAsFixed(0)} € günstiger)'
                            : 'Beobachtet ab ${alert.watchedPriceEur.toStringAsFixed(0)} €',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => provider.removeAlert(alert.id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
