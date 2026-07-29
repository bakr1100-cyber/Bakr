import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/itinerary.dart';
import '../models/trip_leg.dart';

class ItineraryCard extends StatelessWidget {
  const ItineraryCard({super.key, required this.itinerary, this.onTap});

  final Itinerary itinerary;
  final VoidCallback? onTap;

  IconData _iconFor(LegMode mode) => switch (mode) {
        LegMode.flight => Icons.flight_takeoff_rounded,
        LegMode.train => Icons.train_rounded,
        LegMode.bus => Icons.directions_bus_rounded,
        LegMode.taxi => Icons.local_taxi_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.Hm();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${itinerary.totalPriceEur.toStringAsFixed(0)} €',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${timeFormat.format(itinerary.departureTime)} → '
                    '${timeFormat.format(itinerary.arrivalTime)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < itinerary.legs.length; i++) ...[
                    Icon(_iconFor(itinerary.legs[i].mode), size: 20),
                    Text(itinerary.legs[i].to.city),
                    if (i != itinerary.legs.length - 1)
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                itinerary.explanation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
