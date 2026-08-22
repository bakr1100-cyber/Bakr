import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/airport.dart';

/// "Beliebte Ziele in Marokko" from the design mockup - a row of city cards
/// that fill in the destination with one tap.
///
/// The cards use colour, not photographs, on purpose. The mockup's own notes
/// call its city thumbnails placeholders, and the one city picture that did
/// come with it showed the wrong landmark entirely; a card that is honestly
/// abstract is better than one that misidentifies a Moroccan city to
/// Moroccan users. Swap in photographs per city as verified ones appear.
class PopularDestinations extends StatelessWidget {
  const PopularDestinations({super.key, required this.onSelected, this.selected});

  final ValueChanged<Airport> onSelected;
  final Airport? selected;

  /// Ordered by how often the diaspora actually flies there, not
  /// alphabetically.
  static const _codes = ['CMN', 'RAK', 'AGA', 'FEZ', 'TNG', 'RBA'];

  static const _gradients = <String, List<Color>>{
    'CMN': [Color(0xFF16324A), Color(0xFF2E6B8A)],
    'RAK': [Color(0xFF8E3B1F), Color(0xFFD98A45)],
    'AGA': [Color(0xFF0E5A66), Color(0xFF37A6A0)],
    'FEZ': [Color(0xFF3B2A5A), Color(0xFF7A5EA8)],
    'TNG': [Color(0xFF13455C), Color(0xFF4A9BB5)],
    'RBA': [Color(0xFF14512F), Color(0xFF3E9463)],
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final theme = Theme.of(context);
    final airports = [
      for (final code in _codes)
        if (findAirportByCode(code) case final airport?) airport,
    ];
    if (airports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('popularDestinations'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: airports.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final airport = airports[index];
              return _CityCard(
                airport: airport,
                colors: _gradients[airport.code] ?? _gradients['CMN']!,
                isSelected: selected?.code == airport.code,
                onTap: () => onSelected(airport),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.airport,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  final Airport airport;
  final List<Color> colors;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${airport.city} (${airport.code})',
      child: SizedBox(
        width: 132,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  border: isSelected ? Border.all(color: AppColors.heroGold, width: 2) : null,
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        Text(
                          airport.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          airport.code,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
