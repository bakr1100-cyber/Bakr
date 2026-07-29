import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/itinerary.dart';
import '../models/trip_leg.dart';

class ItineraryCard extends StatelessWidget {
  const ItineraryCard({
    super.key,
    required this.itinerary,
    this.onTap,
    this.isBestValue = false,
  });

  final Itinerary itinerary;
  final VoidCallback? onTap;

  /// Highlights this card as the cheapest option in the current result set
  /// (results already arrive sorted ascending by price, so the caller just
  /// passes `index == 0`) — per "highlight the best-value option".
  final bool isBestValue;

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

  String _stopsLabel(String Function(String) t) {
    final stops = itinerary.legs.length - 1;
    if (stops == 0) return t('direct');
    if (stops == 1) return '1 ${t('stop')}';
    return '$stops ${t('stopsPlural')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context).t;
    final timeFormat = DateFormat.Hm();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isBestValue
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: const BorderSide(color: AppColors.moroccoGold, width: 1.6),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBestValue) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.moroccoGold, Color(0xFFC98F2A)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF231A05)),
                      const SizedBox(width: 4),
                      Text(
                        t('bestPrice'),
                        style: const TextStyle(
                          color: Color(0xFF231A05),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${itinerary.totalPriceEur.toStringAsFixed(0)} €',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${t('total')} · ${itinerary.legs.length} '
                          '${itinerary.legs.length == 1 ? t('leg') : t('legsPlural')}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${timeFormat.format(itinerary.departureTime)} → '
                      '${timeFormat.format(itinerary.arrivalTime)}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  _Pill(
                    icon: Icons.schedule_rounded,
                    label: _formatDuration(itinerary.totalDuration),
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    icon: Icons.alt_route_rounded,
                    label: _stopsLabel(t),
                    accent: !itinerary.isDirect,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < itinerary.legs.length; i++) ...[
                    Icon(_iconFor(itinerary.legs[i].mode), size: 18, color: scheme.primary),
                    Text(itinerary.legs[i].to.city, style: theme.textTheme.labelLarge),
                    if (i != itinerary.legs.length - 1)
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: scheme.onSurfaceVariant),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                itinerary.explanation,
                style: theme.textTheme.bodyMedium?.copyWith(
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

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.accent = false});

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ? scheme.secondary : scheme.onSurfaceVariant;
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
