import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/airport.dart';
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
              'Nicht den günstigsten Flug —\nden intelligentesten Weg nach Marokko.',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _VoiceHeroCard(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'ROUTE',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
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
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'WANN & WER',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _DateField(date: search.date, onChanged: search.setDate),
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
              onPressed: search.canSearch
                  ? () async {
                      await search.search();
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
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// A direct, one-tap voice entry point on the landing page itself - jumps
/// straight to the assistant tab and starts listening immediately, instead
/// of making a voice-first user first find the "Berater" tab and then the
/// mic button on their own.
class _VoiceHeroCard extends StatelessWidget {
  const _VoiceHeroCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.read<HomeNavigationProvider>().goToAssistantWithVoice(),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sprich einfach mit mir',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '„Ich will nach Fès, günstig, nächste Woche“',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
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
    final now = DateTime.now();
    final presets = <String, DateTime>{
      'Diese Woche': now.add(const Duration(days: 3)),
      'Nächste Woche': now.add(const Duration(days: 7)),
      'Nächster Monat': now.add(const Duration(days: 30)),
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
  const _DateField({required this.date, required this.onChanged});

  final DateTime date;
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
            initialDate: date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('date'),
            prefixIcon: const Icon(Icons.calendar_today_rounded),
          ),
          child: Text(
            DateFormat.yMMMMd().format(date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
