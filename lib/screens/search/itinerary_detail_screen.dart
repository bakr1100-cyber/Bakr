import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/itinerary.dart';
import '../../models/trip_leg.dart';
import '../../providers/price_alerts_provider.dart';
import '../../widgets/big_button.dart';
import '../companion/travel_companion_screen.dart';

class ItineraryDetailScreen extends StatelessWidget {
  const ItineraryDetailScreen({super.key, required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat.yMMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Reisedetails')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${itinerary.totalPriceEur.toStringAsFixed(0)} €',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(dateFormat.format(itinerary.departureTime)),
          const SizedBox(height: 20),
          Text(
            itinerary.explanation,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          for (final leg in itinerary.legs)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_iconFor(leg.mode), size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${leg.from.city} → ${leg.to.city}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${timeFormat.format(leg.departure)} - '
                            '${timeFormat.format(leg.arrival)} · '
                            '${leg.carrier ?? ''}',
                          ),
                        ],
                      ),
                    ),
                    Text('${leg.priceEur.toStringAsFixed(0)} €'),
                  ],
                ),
              ),
            ),
          Text(itinerary.riskLevel.label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 32),
          BigButton(
            label: 'Buchen & Reisebegleiter aktivieren',
            filled: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TravelCompanionScreen(itinerary: itinerary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'Preis beobachten',
            icon: Icons.notifications_active_outlined,
            onPressed: () {
              context.read<PriceAlertsProvider>().addAlert(
                    itinerary.legs.first.from,
                    itinerary.legs.last.to,
                    itinerary.totalPriceEur,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preisalarm aktiviert.')),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconFor(LegMode mode) => switch (mode) {
        LegMode.flight => Icons.flight_takeoff_rounded,
        LegMode.train => Icons.train_rounded,
        LegMode.bus => Icons.directions_bus_rounded,
        LegMode.taxi => Icons.local_taxi_rounded,
      };
}
