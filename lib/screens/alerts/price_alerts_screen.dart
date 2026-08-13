import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/price_alert.dart';
import '../../providers/price_alerts_provider.dart';
import '../../services/pwa_install_hint.dart';
import '../../widgets/responsive_body.dart';

const _homeScreenHintDismissedKey = 'price_alerts_home_screen_hint_dismissed';

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  bool _checking = false;
  bool _showHomeScreenHint = false;

  @override
  void initState() {
    super.initState();
    _loadHomeScreenHintState();
  }

  Future<void> _loadHomeScreenHintState() async {
    // Real push notifications only ever arrive while this is running as an
    // installed PWA - a page open in a normal Safari tab (iPad's only
    // browser choice) can't receive them at all, no matter how well the
    // rest of the notification pipeline works. Nudge the user toward that
    // one-time setup step instead of leaving them wondering why nothing
    // ever arrives.
    if (!kIsWeb || isRunningAsInstalledPwa()) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(_homeScreenHintDismissedKey) != true) {
      setState(() => _showHomeScreenHint = true);
    }
  }

  Future<void> _dismissHomeScreenHint() async {
    setState(() => _showHomeScreenHint = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeScreenHintDismissedKey, true);
  }

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
        child: Column(
          children: [
            if (_showHomeScreenHint) _HomeScreenHintBanner(onDismiss: _dismissHomeScreenHint),
            Expanded(child: _buildBody(context, provider, theme, t)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PriceAlertsProvider provider,
    ThemeData theme,
    String Function(String) t,
  ) {
    return provider.alerts.isEmpty
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
              );
  }
}

class _HomeScreenHintBanner extends StatelessWidget {
  const _HomeScreenHintBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.moroccoGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.ios_share_rounded, size: 20, color: theme.colorScheme.tertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              t('addToHomeScreenHint'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
