import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/companion_event.dart';
import '../../models/itinerary.dart';
import '../../services/travel_companion_service.dart';
import '../../widgets/responsive_body.dart';

class TravelCompanionScreen extends StatelessWidget {
  const TravelCompanionScreen({super.key, this.itinerary});

  final Itinerary? itinerary;

  static final _service = TravelCompanionService();

  String _stageTitle(BuildContext context, CompanionStage stage) {
    final t = AppLocalizations.of(context).t;
    return switch (stage) {
      CompanionStage.beforeTrip => t('stageBeforeTrip'),
      CompanionStage.atAirport => t('stageAtAirport'),
      CompanionStage.duringFlight => t('stageDuringFlight'),
      CompanionStage.afterLanding => t('stageAfterLanding'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;

    if (itinerary == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('travelCompanion'))),
        body: ResponsiveBody(
          child: Center(
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
                      color: AppColors.moroccoGreen.withValues(alpha: 0.16),
                    ),
                    child: Icon(Icons.explore_outlined,
                        size: 38, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(t('noActiveTripTitle'), style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t('noActiveTripBody'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final events =
        _service.buildTimeline(itinerary!, language: AppLocalizations.of(context).language);
    final grouped = <CompanionStage, List<CompanionEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.stage, () => []).add(event);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('travelCompanion'))),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final stage in CompanionStage.values)
              if (grouped[stage]?.isNotEmpty ?? false) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, AppSpacing.sm),
                  child: Text(
                    _stageTitle(context, stage).toUpperCase(),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                for (final event in grouped[stage]!)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      leading: CircleAvatar(
                        backgroundColor: event.isUrgent
                            ? theme.colorScheme.error.withValues(alpha: 0.18)
                            : AppColors.moroccoGreen.withValues(alpha: 0.16),
                        foregroundColor:
                            event.isUrgent ? theme.colorScheme.error : theme.colorScheme.primary,
                        child: Icon(
                          event.isUrgent
                              ? Icons.notifications_active_rounded
                              : Icons.info_outline_rounded,
                        ),
                      ),
                      title: Text(event.title, style: theme.textTheme.titleMedium),
                      subtitle: Text(event.message),
                      trailing: Text(
                        DateFormat.Hm().format(event.timestamp),
                        style: theme.textTheme.bodySmall,
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
