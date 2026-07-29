import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/search_provider.dart';
import '../../widgets/itinerary_card.dart';
import '../../widgets/skeleton_loader.dart';
import 'itinerary_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${search.origin?.city} → ${search.destination?.city}'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: search.isLoading
            ? const _LoadingList(key: ValueKey('loading'))
            : search.results.isEmpty
                ? const _EmptyState(key: ValueKey('empty'))
                : ListView.builder(
                    key: const ValueKey('results'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: search.results.length,
                    itemBuilder: (context, index) {
                      final itinerary = search.results[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ItineraryCard(
                          itinerary: itinerary,
                          isBestValue: index == 0,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ItineraryDetailScreen(itinerary: itinerary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Row(
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 12),
              Text(
                'Ich suche die besten Verbindungen für dich…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: ShimmerLoader(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: ItineraryCardSkeleton(),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: ItineraryCardSkeleton(),
                ),
                ItineraryCardSkeleton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
              child: Icon(
                Icons.travel_explore_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Noch keine Verbindung gefunden',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Für diese Route ist gerade nichts dabei. Probier ein anderes '
              'Datum oder Ziel — ich suche automatisch auch Zug- und '
              'Bus-Kombinationen mit.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
