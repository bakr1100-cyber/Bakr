import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/price_alert.dart';
import '../../providers/price_alerts_provider.dart';
import '../../widgets/responsive_body.dart';

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  bool _checking = false;

  Future<void> _checkForDrops(PriceAlertsProvider provider) async {
    if (_checking) return;
    setState(() => _checking = true);
    final language = AppLocalizations.of(context).language;
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context).t;
    final dropsFound = await provider.checkForDrops(language: language);
    if (!mounted) return;
    setState(() => _checking = false);
    final message = dropsFound == 0
        ? t('noPriceChangeFound')
        : dropsFound == 1
            ? t('onePriceDropped')
            : t('pricesDropped').replaceAll('{count}', '$dropsFound');
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _deleteAlert(BuildContext context, PriceAlertsProvider provider, PriceAlert alert) {
    final t = AppLocalizations.of(context).t;
    final index = provider.alerts.indexOf(alert);
    provider.removeAlert(alert.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('alertDeletedMessage')),
        action: SnackBarAction(
          label: t('undo'),
          onPressed: () => provider.restoreAlert(index, alert),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceAlertsProvider>();
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('priceAlerts')),
        actions: [
          IconButton(
            tooltip: t('checkForPriceDrops'),
            icon: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _checking ? null : () => _checkForDrops(provider),
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
                      Text(t('noAlertsYetTitle'), style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t('noAlertsYetBody'),
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
                              ? '${t('nowCheaper')} ${alert.currentPriceEur!.toStringAsFixed(0)} € '
                                  '(${alert.dropEur!.toStringAsFixed(0)} € ${t('cheaper')})'
                              : '${t('watchedFrom')} ${alert.watchedPriceEur.toStringAsFixed(0)} €',
                          style: TextStyle(
                            color: alert.dropEur != null && alert.dropEur! > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: t('deleteAlert'),
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _deleteAlert(context, provider, alert),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
