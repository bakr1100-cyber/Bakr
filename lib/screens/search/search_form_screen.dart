import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/airport.dart';
import '../../models/trip_type.dart';
import '../../providers/home_navigation_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/airport_picker.dart';
import '../../widgets/big_button.dart';
import '../../widgets/city_hero_header.dart';
import '../../widgets/popular_destinations.dart';
import '../../widgets/trust_badges_row.dart';
import '../../widgets/passenger_counter.dart';
import '../../widgets/responsive_body.dart';
import 'search_results_screen.dart';

/// The three-tap fast path: pick origin, pick destination, tap search.
/// Date defaults to next week and passengers defaults to 1 so a user who
/// wants the golden path can be searching in exactly three taps.
class SearchFormScreen extends StatelessWidget {
  const SearchFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      // No AppBar: the photo header from the design mockup takes its place
      // and carries the greeting and headline itself.
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          CityHeroHeader(
            destination: search.destination,
            trailing: _NotificationsBell(
              onTap: () => context.read<HomeNavigationProvider>().goToTab(
                    HomeNavigationProvider.alertsTabIndex,
                  ),
            ),
          ),
          // Sits directly against the header's lower (already-dark,
          // text-free) edge, its own card elevation/shadow doing the work of
          // reading as "resting on" the photo above it, per the design
          // mockup.
          ResponsiveBody(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: _SearchCard(search: search, t: t),
              ),
            ),
          ),
          ResponsiveBody(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TrustBadgesRow(),
                  const SizedBox(height: AppSpacing.xxl),
                  PopularDestinations(
                    selected: search.destination,
                    onSelected: search.setDestination,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const _VoiceHeroCard(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The flight-search form itself, as one card directly beneath the photo
/// header - trip type, route, dates and travellers all in the one place a
/// traveller expects to find them immediately, rather than several taps of
/// scrolling below the landing page's decorative sections.
class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.search, required this.t});

  final SearchProvider search;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TripTypeSelector(tripType: search.tripType, onChanged: search.setTripType),
            const SizedBox(height: AppSpacing.lg),
            AirportPicker(
              label: t('from'),
              options: europeanAirports,
              selected: search.origin,
              onChanged: search.setOrigin,
            ),
            const SizedBox(height: AppSpacing.md),
            AirportPicker(
              label: t('to'),
              icon: Icons.flight_land_rounded,
              options: moroccanAirports,
              selected: search.destination,
              onChanged: search.setDestination,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (search.tripType == TripType.roundTrip)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DateField(
                      label: t('date'),
                      date: search.date,
                      firstDate: DateTime.now(),
                      onChanged: search.setDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DateField(
                      label: t('returnDate'),
                      date: search.returnDate ?? search.date,
                      firstDate: search.date,
                      onChanged: search.setReturnDate,
                    ),
                  ),
                ],
              )
            else
              _DateField(
                label: t('date'),
                date: search.date,
                firstDate: DateTime.now(),
                onChanged: search.setDate,
              ),
            const SizedBox(height: AppSpacing.md),
            _QuickDateChips(selected: search.date, onChanged: search.setDate),
            const SizedBox(height: AppSpacing.md),
            PassengerCounter(count: search.passengers, onChanged: search.setPassengers),
            const SizedBox(height: AppSpacing.xl),
            BigButton(
              label: t('searchFlights'),
              icon: Icons.search_rounded,
              loading: search.isLoading,
              onPressed: search.canSearch && !search.isLoading
                  ? () async {
                      await search.search(language: AppLocalizations.of(context).language);
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
                        );
                      }
                    }
                  : null,
            ),
            if (!search.canSearch) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  t('completeDetailsToSearch'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One-way / round-trip toggle - visually the first thing inside the route
/// card, since it changes what the rest of the form asks for.
class _TripTypeSelector extends StatelessWidget {
  const _TripTypeSelector({required this.tripType, required this.onChanged});

  final TripType tripType;
  final ValueChanged<TripType> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          _TripTypeTab(
            label: t('oneWay'),
            selected: tripType == TripType.oneWay,
            onTap: () => onChanged(TripType.oneWay),
          ),
          _TripTypeTab(
            label: t('roundTrip'),
            selected: tripType == TripType.roundTrip,
            onTap: () => onChanged(TripType.roundTrip),
          ),
        ],
      ),
    );
  }
}

/// A single understated text tab, gold-underlined when selected - the
/// design mockup's tab style (plain labels, a thin colored indicator),
/// not a heavy filled segmented control.
class _TripTypeTab extends StatelessWidget {
  const _TripTypeTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.moroccoGold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// The bell in the header's top-right corner, from the design mockup -
/// jumps straight to the price-alerts tab, since that is the one thing a
/// notification in this app is ever about.
class _NotificationsBell extends StatelessWidget {
  const _NotificationsBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(side: BorderSide(color: Color(0x38FFFFFF))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Colors.white.withValues(alpha: 0.92),
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// A direct, one-tap voice entry point on the landing page itself - jumps
/// straight to the assistant tab and starts listening immediately, instead
/// of making a voice-first user first find the "Berater" tab and then the
/// mic button on their own. Deliberately the single biggest, boldest thing
/// on the landing page - voice is the primary way in, not an afterthought.
class _VoiceHeroCard extends StatelessWidget {
  const _VoiceHeroCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppLocalizations.of(context).t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.read<HomeNavigationProvider>().goToAssistantWithVoice(),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.floating(AppColors.moroccoGold),
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t('talkToMe'),
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t('voiceExamplePrompt'),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('talkNow'),
                      style: textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-tap shortcuts for the most common travel dates, so most searches
/// never need the full date-picker dialog at all.
class _QuickDateChips extends StatelessWidget {
  const _QuickDateChips({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final now = DateTime.now();
    final presets = <String, DateTime>{
      t('thisWeek'): now.add(const Duration(days: 3)),
      t('nextWeek'): now.add(const Duration(days: 7)),
      t('nextMonth'): now.add(const Duration(days: 30)),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in presets.entries)
            ChoiceChip(
              label: Text(entry.key),
              selected: _isSameDay(selected, entry.value),
              onSelected: (_) => onChanged(entry.value),
            ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.firstDate,
    required this.onChanged,
  });

  final String label;
  final DateTime date;
  final DateTime firstDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date.isBefore(firstDate) ? firstDate : date,
            firstDate: firstDate,
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_rounded),
          ),
          child: Text(
            DateFormat.yMMMMd(AppLocalizations.of(context).language.flutterLocale.languageCode)
                .format(date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
