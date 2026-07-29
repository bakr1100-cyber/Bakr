import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/price_alerts_provider.dart';
import '../../widgets/responsive_body.dart';

class PriceAlertsScreen extends StatelessWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceAlertsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preisalarme'),
        actions: [
          IconButton(
            tooltip: 'Auf Preisänderungen prüfen',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: provider.checkForDrops,
          ),
        ],
      ),
      body: ResponsiveBody(
        child: provider.alerts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.moroccoGold.withValues(alpha: 0.18),
                        ),
                        child: Icon(Icons.notifications_active_outlined,
                            size: 38, color: theme.colorScheme.tertiary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Noch keine Preisalarme', style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Aktiviere bei einer Reise "Preis beobachten", und ich '
                        'melde mich, sobald sie günstiger wird.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (final alert in provider.alerts)
                    Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                        leading: CircleAvatar(
                          backgroundColor: alert.dropEur != null && alert.dropEur! > 0
                              ? AppColors.moroccoGreen.withValues(alpha: 0.18)
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.14),
                          foregroundColor: alert.dropEur != null && alert.dropEur! > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          child: Icon(
                            alert.dropEur != null && alert.dropEur! > 0
                                ? Icons.trending_down_rounded
                                : Icons.visibility_outlined,
                          ),
                        ),
                        title: Text(
                          '${alert.origin.city} → ${alert.destination.city}',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          alert.dropEur != null && alert.dropEur! > 0
                              ? 'Jetzt ${alert.currentPriceEur!.toStringAsFixed(0)} € '
                                  '(${alert.dropEur!.toStringAsFixed(0)} € günstiger)'
                              : 'Beobachtet ab ${alert.watchedPriceEur.toStringAsFixed(0)} €',
                          style: TextStyle(
                            color: alert.dropEur != null && alert.dropEur! > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => provider.removeAlert(alert.id),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
