import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/itinerary.dart';
import '../models/trip_leg.dart';

/// A creative, AI-assembled option (different airport, flight+train/bus,
/// multi-airline) shown only inside the collapsed "Alternative
/// Reisemöglichkeiten" section - always paired with its savings vs. the
/// direct flight and any extra travel time, so the user can weigh the
/// trade-off before opening it.
class AlternativeItineraryCard extends StatelessWidget {
  const AlternativeItineraryCard({super.key, required this.itinerary, this.onTap});

  final Itinerary itinerary;
  final VoidCallback? onTap;

  IconData _iconFor(LegMode mode) => switch (mode) {
        LegMode.flight => Icons.flight_takeoff_rounded,
        LegMode.train => Icons.train_rounded,
        LegMode.bus => Icons.directions_bus_rounded,
        LegMode.taxi => Icons.local_taxi_rounded,
      };

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context).t;
    final timeFormat = DateFormat.Hm();
    final savings = itinerary.savingsEur;
    final extraTime = itinerary.extraTravelTime;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: scheme.secondary.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: scheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${itinerary.totalPriceEur.toStringAsFixed(0)} €',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (savings != null && savings > 0)
                    _StatPill(
                      icon: Icons.savings_rounded,
                      label: '${t('savings')}: -${savings.toStringAsFixed(0)} €',
                      color: AppColors.moroccoGreen,
                    ),
                  if (extraTime != null && extraTime > Duration.zero)
                    _StatPill(
                      icon: Icons.schedule_rounded,
                      label: '${t('extraTravelTime')}: +${_formatDuration(extraTime)}',
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    '${timeFormat.format(itinerary.departureTime)} → '
                    '${timeFormat.format(itinerary.arrivalTime)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < itinerary.legs.length; i++) ...[
                    Icon(_iconFor(itinerary.legs[i].mode), size: 16, color: scheme.primary),
                    Text(itinerary.legs[i].to.city, style: theme.textTheme.labelLarge),
                    if (i != itinerary.legs.length - 1)
                      Icon(Icons.arrow_forward_rounded,
                          size: 13, color: scheme.onSurfaceVariant),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                itinerary.explanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.tertiary,
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

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
