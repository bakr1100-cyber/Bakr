import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/itinerary.dart';
import '../../models/trip_type.dart';
import '../../providers/search_provider.dart';
import '../../widgets/itinerary_card.dart';
import '../../widgets/skeleton_loader.dart';
import 'itinerary_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final isRoundTrip = search.tripType == TripType.roundTrip;
    final bothEmpty = search.results.isEmpty && (!isRoundTrip || search.returnResults.isEmpty);

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
            : bothEmpty
                ? const _EmptyState(key: ValueKey('empty'))
                : _ResultsList(
                    key: const ValueKey('results'),
                    isRoundTrip: isRoundTrip,
                  ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({super.key, required this.isRoundTrip});

  final bool isRoundTrip;

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final t = AppLocalizations.of(context).t;

    if (!isRoundTrip) {
      return _ItineraryList(itineraries: search.results, padding: const EdgeInsets.all(AppSpacing.lg));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionHeader(icon: Icons.flight_takeoff_rounded, label: t('outboundFlight')),
        const SizedBox(height: AppSpacing.sm),
        _ItineraryList(itineraries: search.results, padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.xxl),
        _SectionHeader(icon: Icons.flight_land_rounded, label: t('returnFlight')),
        const SizedBox(height: AppSpacing.sm),
        _ItineraryList(itineraries: search.returnResults, padding: EdgeInsets.zero),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ItineraryList extends StatelessWidget {
  const _ItineraryList({required this.itineraries, required this.padding});

  final List<Itinerary> itineraries;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (itineraries.isEmpty) {
      return Padding(
        padding: padding,
        child: Text(
          AppLocalizations.of(context).t('noRouteFoundTitle'),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itineraries.length,
      itemBuilder: (context, index) {
        final itinerary = itineraries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ItineraryCard(
            itinerary: itinerary,
            isBestValue: index == 0,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItineraryDetailScreen(itinerary: itinerary),
              ),
            ),
          ),
        );
      },
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
                AppLocalizations.of(context).t('searchingBestRoutes'),
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
    final t = AppLocalizations.of(context).t;
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
              t('noRouteFoundTitle'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t('noRouteFoundBody'),
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
