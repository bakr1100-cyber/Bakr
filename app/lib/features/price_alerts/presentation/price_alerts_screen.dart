import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/price_alerts_controller.dart';

class PriceAlertsScreen extends ConsumerWidget {
  const PriceAlertsScreen({super.key});

  void _showAddAlertSheet(BuildContext context, WidgetRef ref) {
    final originController = TextEditingController();
    final destinationController = TextEditingController();
    final maxPriceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: originController,
                decoration: const InputDecoration(labelText: 'Abflugort'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: 'Ziel'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxPriceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Maximalpreis (€)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final maxPrice =
                      double.tryParse(maxPriceController.text) ?? 0;
                  if (originController.text.isEmpty ||
                      destinationController.text.isEmpty ||
                      maxPrice <= 0) {
                    return;
                  }
                  ref.read(priceAlertsControllerProvider.notifier).addAlert(
                        origin: originController.text,
                        destination: destinationController.text,
                        maxPrice: maxPrice,
                      );
                  Navigator.of(context).pop();
                },
                child: const Text('Preisalarm erstellen'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(priceAlertsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Preisalarm')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlertSheet(context, ref),
        child: const Icon(Icons.add_alert),
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('Noch keine Preisalarme.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      alert.isTriggered
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: alert.isTriggered ? Colors.green : null,
                    ),
                    title: Text('${alert.origin} → ${alert.destination}'),
                    subtitle: Text(
                      'Aktuell ${alert.currentPrice.toStringAsFixed(0)} '
                      '${alert.currency} · Ziel ${alert.maxPrice.toStringAsFixed(0)} '
                      '${alert.currency}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(priceAlertsControllerProvider.notifier)
                          .removeAlert(alert.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
