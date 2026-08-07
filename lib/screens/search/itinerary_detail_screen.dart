import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/itinerary.dart';
import '../../models/trip_leg.dart';
import '../../providers/price_alerts_provider.dart';
import '../../services/affiliate_service.dart';
import '../../widgets/big_button.dart';
import '../../widgets/responsive_body.dart';
import '../companion/travel_companion_screen.dart';

class ItineraryDetailScreen extends StatelessWidget {
  const ItineraryDetailScreen({super.key, required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final dateFormat =
        DateFormat.yMMMMd(AppLocalizations.of(context).language.flutterLocale.languageCode);
    final affiliate = context.read<AffiliateService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t('tripDetails'))),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryDeep,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${itinerary.totalPriceEur.toStringAsFixed(0)} €',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(itinerary.departureTime),
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    itinerary.explanation,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.moroccoGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (itinerary.legs.length > 1) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t('multiStopNotice'),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        itinerary.riskLevel == RiskLevel.low
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t(switch (itinerary.riskLevel) {
                          RiskLevel.low => 'riskLow',
                          RiskLevel.medium => 'riskMedium',
                          RiskLevel.high => 'riskHigh',
                        }),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              t('legsSectionLabel'),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < itinerary.legs.length; i++)
              _LegCard(
                leg: itinerary.legs[i],
                affiliate: affiliate,
                isLast: i == itinerary.legs.length - 1,
              ),
            const SizedBox(height: AppSpacing.xxl),
            BigButton(
              label: t('activateCompanion'),
              filled: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TravelCompanionScreen(itinerary: itinerary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BigButton(
              label: t('watchPrice'),
              icon: Icons.notifications_active_outlined,
              onPressed: () {
                context.read<PriceAlertsProvider>().addAlert(
                      itinerary.legs.first.from,
                      itinerary.legs.last.to,
                      itinerary.totalPriceEur,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('priceAlertActivated'))),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// One leg of the itinerary, with its own "book this" action: a
/// commission-tracked affiliate link for flights, or a plain link to the
/// operator's own site for trains (no rail affiliate program wired up).
class _LegCard extends StatelessWidget {
  const _LegCard({required this.leg, required this.affiliate, required this.isLast});

  final TripLeg leg;
  final AffiliateService affiliate;
  final bool isLast;

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
        SnackBar(content: Text(AppLocalizations.of(context).t('bookingLinkFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;
    final timeFormat = DateFormat.Hm();
    final canBook = leg.mode == LegMode.flight || leg.mode == LegMode.train;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(leg.mode), size: 18, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${leg.from.city} → ${leg.to.city}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${leg.priceEur.toStringAsFixed(0)} €',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${timeFormat.format(leg.departure)} – '
                        '${timeFormat.format(leg.arrival)}'
                        '${leg.carrier != null ? " · ${leg.carrier}" : ""}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (canBook) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openBookingLink(context),
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            label: Text(
                              leg.mode == LegMode.flight
                                  ? t('bookFlight')
                                  : t('bookTrainTicket'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
