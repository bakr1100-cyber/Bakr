import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/preferences_provider.dart';
import '../../widgets/responsive_body.dart';

/// Shows what the app has learned about the user - favorite airports,
/// airlines, budget, family vs. solo travel - per the "Persönliche
/// Empfehlungen" feature. Currently populated only from what the user sets
/// explicitly in Settings/search; a production build should also derive
/// this from booking history.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>().preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Deine Reisevorlieben')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _InfoTile(
              icon: Icons.flight_takeoff_rounded,
              color: AppColors.moroccoGreen,
              label: 'Lieblingsflughafen (Abflug)',
              value: prefs.favoriteOriginAirportCode ?? 'Noch nicht bekannt',
            ),
            _InfoTile(
              icon: Icons.flight_land_rounded,
              color: AppColors.moroccoGold,
              label: 'Lieblingsziel',
              value: prefs.favoriteDestinationAirportCode ?? 'Noch nicht bekannt',
            ),
            _InfoTile(
              icon: Icons.airlines_rounded,
              color: AppColors.moroccoRed,
              label: 'Lieblingsairlines',
              value: prefs.favoriteAirlines.isEmpty
                  ? 'Noch nicht bekannt'
                  : prefs.favoriteAirlines.join(', '),
            ),
            _InfoTile(
              icon: Icons.payments_outlined,
              color: AppColors.moroccoGold,
              label: 'Übliches Budget',
              value: prefs.usualMaxBudgetEur != null
                  ? '${prefs.usualMaxBudgetEur!.toStringAsFixed(0)} €'
                  : 'Noch nicht bekannt',
            ),
            _InfoTile(
              icon: Icons.family_restroom_rounded,
              color: AppColors.moroccoGreen,
              label: 'Reisestil',
              value: prefs.travelsWithFamily ? 'Mit Familie' : 'Alleinreisend',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(label, style: theme.textTheme.bodySmall),
        subtitle: Text(value, style: theme.textTheme.titleMedium),
      ),
    );
  }
}
