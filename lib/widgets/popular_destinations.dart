import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/airport.dart';

/// "Beliebte Ziele in Marokko" from the design mockup - a row of city cards
/// that fill in the destination with one tap.
///
/// Cities with a verified photo (one that genuinely shows that city, not a
/// generic or mislabeled stand-in) get it; anything else falls back to a
/// solid gradient rather than risk showing a Moroccan user the wrong
/// landmark for their own city. Swap in a photo per city as verified ones
/// appear - see [CityHeroHeader] for the same policy on the header photo.
class PopularDestinations extends StatelessWidget {
  const PopularDestinations({super.key, required this.onSelected, this.selected});

  final ValueChanged<Airport> onSelected;
  final Airport? selected;

  /// Ordered by how often the diaspora actually flies there, not
  /// alphabetically.
  static const _codes = ['CMN', 'RAK', 'AGA', 'FEZ', 'TNG', 'RBA'];

  static const _images = <String, String>{
    'CMN': 'assets/images/hero_casablanca.jpg',
    'RAK': 'assets/images/hero_marrakech.jpg',
    'FEZ': 'assets/images/hero_fes.jpg',
  };

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
                image: _images[airport.code],
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
    required this.image,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  final Airport airport;
  final String? image;
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (image != null)
                        Image.asset(
                          image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      if (image != null)
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xB3000000)],
                              stops: [0.4, 1],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                    ],
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
