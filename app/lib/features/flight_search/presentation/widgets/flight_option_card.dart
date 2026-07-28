import 'package:flutter/material.dart';

import '../../../../core/models/flight_option.dart';
import '../../../../core/models/transport_leg.dart';

class FlightOptionCard extends StatelessWidget {
  const FlightOptionCard({super.key, required this.option});

  final FlightOption option;

  IconData _iconFor(TransportMode mode) {
    switch (mode) {
      case TransportMode.flight:
        return Icons.flight;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.taxi:
        return Icons.local_taxi;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${option.origin} → ${option.destination}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${option.totalPrice.toStringAsFixed(0)} ${option.currency}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final leg in option.legs)
                  Chip(
                    avatar: Icon(_iconFor(leg.mode), size: 18),
                    label: Text('${leg.carrier} · ${leg.from}–${leg.to}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(option.explanation, style: theme.textTheme.bodyMedium),
            if (option.savingsVsCheapestDirect != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ersparnis: ${option.savingsVsCheapestDirect!.toStringAsFixed(0)} €',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
