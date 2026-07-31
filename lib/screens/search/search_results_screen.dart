import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/itinerary.dart';
import '../../models/trip_type.dart';
import '../../providers/search_provider.dart';
import '../../widgets/alternative_itinerary_card.dart';
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
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [_ResultsSection(itineraries: search.results)],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionHeader(icon: Icons.flight_takeoff_rounded, label: t('outboundFlight')),
        const SizedBox(height: AppSpacing.sm),
        _ResultsSection(itineraries: search.results),
        const SizedBox(height: AppSpacing.xxl),
        _SectionHeader(icon: Icons.flight_land_rounded, label: t('returnFlight')),
        const SizedBox(height: AppSpacing.sm),
        _ResultsSection(itineraries: search.returnResults),
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

/// Standard results (direct + a real layover via Casablanca) are shown
/// immediately, sorted purely by price. Creative alternatives (other
/// airports, flight+train/bus, multi-airline) stay collapsed behind a
/// "Weitere Möglichkeiten anzeigen" toggle so the main results page stays
/// simple - see "Flugsuche – Reihenfolge der Suchergebnisse und
/// Alternativen".
class _ResultsSection extends StatefulWidget {
  const _ResultsSection({required this.itineraries});

  final List<Itinerary> itineraries;

  @override
  State<_ResultsSection> createState() => _ResultsSectionState();
}

class _ResultsSectionState extends State<_ResultsSection> {
  bool _showAlternatives = false;

  void _openDetail(BuildContext context, Itinerary itinerary) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItineraryDetailScreen(itinerary: itinerary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final standard =
        widget.itineraries.where((i) => i.tier == ResultTier.standard).toList();
    final alternatives =
        widget.itineraries.where((i) => i.tier == ResultTier.alternative).toList();

    if (standard.isEmpty && alternatives.isEmpty) {
      return Text(
        t('noRouteFoundTitle'),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < standard.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ItineraryCard(
              itinerary: standard[i],
              isBestValue: i == 0,
              onTap: () => _openDetail(context, standard[i]),
            ),
          ),
        if (alternatives.isNotEmpty)
          if (!_showAlternatives)
            _ShowMoreButton(
              count: alternatives.length,
              onTap: () => setState(() => _showAlternatives = true),
            )
          else ...[
            const SizedBox(height: AppSpacing.sm),
            _SectionHeader(
              icon: Icons.auto_awesome_rounded,
              label: t('alternativeOptionsTitle'),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final alt in alternatives)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AlternativeItineraryCard(
                  itinerary: alt,
                  onTap: () => _openDetail(context, alt),
                ),
              ),
          ],
      ],
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
      ),
      icon: Icon(Icons.auto_awesome_rounded, size: 18, color: theme.colorScheme.secondary),
      label: Text('${t('showMoreOptions')} ($count)'),
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
