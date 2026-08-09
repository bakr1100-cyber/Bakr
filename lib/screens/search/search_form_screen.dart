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
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      appBar: AppBar(title: const Text('MarocFly AI')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              t('tagline'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _VoiceHeroCard(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              t('routeSectionLabel'),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _TripTypeSelector(
                      tripType: search.tripType,
                      onChanged: search.setTripType,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AirportPicker(
                            label: t('from'),
                            compact: true,
                            options: europeanAirports,
                            selected: search.origin,
                            onChanged: search.setOrigin,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: AirportPicker(
                            label: t('to'),
                            icon: Icons.flight_land_rounded,
                            compact: true,
                            options: moroccanAirports,
                            selected: search.destination,
                            onChanged: search.setDestination,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              t('whenAndWhoSectionLabel'),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _DateField(
                      label: t('date'),
                      date: search.date,
                      firstDate: DateTime.now(),
                      onChanged: search.setDate,
                    ),
                    if (search.tripType == TripType.roundTrip) ...[
                      const SizedBox(height: AppSpacing.md),
                      _DateField(
                        label: t('returnDate'),
                        date: search.returnDate ?? search.date,
                        firstDate: search.date,
                        onChanged: search.setReturnDate,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _QuickDateChips(selected: search.date, onChanged: search.setDate),
                    const SizedBox(height: AppSpacing.md),
                    PassengerCounter(
                      count: search.passengers,
                      onChanged: search.setPassengers,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            BigButton(
              label: t('searchFlights'),
              icon: Icons.search_rounded,
              loading: search.isLoading,
              onPressed: search.canSearch && !search.isLoading
                  ? () async {
                      await search.search(language: AppLocalizations.of(context).language);
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SearchResultsScreen(),
                          ),
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
            const SizedBox(height: AppSpacing.lg),
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
    return SegmentedButton<TripType>(
      segments: [
        ButtonSegment(
          value: TripType.oneWay,
          label: Text(t('oneWay')),
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        ),
        ButtonSegment(
          value: TripType.roundTrip,
          label: Text(t('roundTrip')),
          icon: const Icon(Icons.sync_alt_rounded, size: 16),
        ),
      ],
      selected: {tripType},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
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
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
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
