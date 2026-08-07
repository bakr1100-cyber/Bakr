import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
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
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('priceAlerts')),
        actions: [
          IconButton(
            tooltip: t('checkForPriceDrops'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              final language = AppLocalizations.of(context).language;
              final messenger = ScaffoldMessenger.of(context);
              final dropsFound = await provider.checkForDrops(language: language);
              messenger.showSnackBar(
                SnackBar(content: Text(_checkResultMessage(language, dropsFound))),
              );
            },
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

/// System notifications can't be relied on to reach the user (no-op on web,
/// see [NotificationService]) - this is the message shown directly in-app
/// right after a manual price check, so the result is always visible
/// regardless of platform/notification permission.
String _checkResultMessage(AppLanguage language, int dropsFound) {
  if (dropsFound == 0) {
    return switch (language) {
      AppLanguage.de => 'Keine Preisänderung gefunden.',
      AppLanguage.fr => 'Aucun changement de prix trouvé.',
      AppLanguage.en => 'No price change found.',
      AppLanguage.ar => 'لم يتم العثور على تغيير في السعر.',
      AppLanguage.ary => 'مالقيتش تبديل فالثمن.',
    };
  }
  return switch (language) {
    AppLanguage.de =>
      dropsFound == 1 ? '1 Preis ist gefallen!' : '$dropsFound Preise sind gefallen!',
    AppLanguage.fr =>
      dropsFound == 1 ? '1 prix a baissé !' : '$dropsFound prix ont baissé !',
    AppLanguage.en => dropsFound == 1 ? '1 price dropped!' : '$dropsFound prices dropped!',
    AppLanguage.ar => 'انخفض سعر $dropsFound رحلة!',
    AppLanguage.ary => 'هبط الثمن ديال $dropsFound طيارة!',
  };
}
