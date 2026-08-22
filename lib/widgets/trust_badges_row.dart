import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_spacing.dart';

/// The reassurance strip from the design mockup, sitting directly under the
/// search card.
///
/// Each claim here is one this app can actually keep, which is why the
/// mockup's "Sicher buchen" wording is not used verbatim: Tayarti never
/// takes a booking or a payment, it hands travellers to the airline, and
/// promising secure checkout would be claiming something that does not
/// happen. The badge says that hand-off instead.
class TrustBadgesRow extends StatelessWidget {
  const TrustBadgesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          _Badge(
            icon: Icons.savings_outlined,
            title: t('trustBestPriceTitle'),
            subtitle: t('trustBestPriceSubtitle'),
          ),
          _Divider(color: theme.dividerColor),
          _Badge(
            icon: Icons.flight_takeoff_rounded,
            title: t('trustDirectTitle'),
            subtitle: t('trustDirectSubtitle'),
          ),
          _Divider(color: theme.dividerColor),
          _Badge(
            icon: Icons.record_voice_over_outlined,
            title: t('trustDarijaTitle'),
            subtitle: t('trustDarijaSubtitle'),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: color.withValues(alpha: 0.5));
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
