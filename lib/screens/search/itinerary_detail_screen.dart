import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/itinerary.dart';
import '../../models/trip_leg.dart';
import '../../providers/price_alerts_provider.dart';
import '../../services/affiliate_service.dart';
import '../../widgets/big_button.dart';
import '../companion/travel_companion_screen.dart';

class ItineraryDetailScreen extends StatelessWidget {
  const ItineraryDetailScreen({super.key, required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final affiliate = context.read<AffiliateService>();

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
          if (itinerary.legs.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Mehrteilige Reise: jede Etappe wird separat gebucht.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          for (final leg in itinerary.legs)
            _LegCard(leg: leg, affiliate: affiliate),
          Text(itinerary.riskLevel.label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 32),
          BigButton(
            label: 'Reisebegleiter aktivieren',
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
}

/// One leg of the itinerary, with its own "book this" action: a
/// commission-tracked affiliate link for flights, or a plain link to the
/// operator's own site for trains (no rail affiliate program wired up).
class _LegCard extends StatelessWidget {
  const _LegCard({required this.leg, required this.affiliate});

  final TripLeg leg;
  final AffiliateService affiliate;

  IconData _iconFor(LegMode mode) => switch (mode) {
        LegMode.flight => Icons.flight_takeoff_rounded,
        LegMode.train => Icons.train_rounded,
        LegMode.bus => Icons.directions_bus_rounded,
        LegMode.taxi => Icons.local_taxi_rounded,
      };

  Future<void> _openBookingLink(BuildContext context) async {
    final url = leg.mode == LegMode.flight
        ? affiliate.affiliateBookingUrl(leg)
        : affiliate.officialBookingUrl(leg);

    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Buchungslink konnte nicht geöffnet werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.Hm();
    final canBook = leg.mode == LegMode.flight || leg.mode == LegMode.train;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            if (canBook) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openBookingLink(context),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    leg.mode == LegMode.flight ? 'Flug buchen' : 'Zugticket buchen',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
