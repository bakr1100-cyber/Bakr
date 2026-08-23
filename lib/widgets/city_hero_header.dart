import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/airport.dart';

/// Photographic header for the search screen, from the design mockup: a
/// Moroccan skyline at dusk, a night-blue wash over it, and the headline
/// naming wherever the traveller is currently heading.
///
/// The photo follows the chosen destination. Only cities with a picture
/// that genuinely shows that city get their own - anything else falls back
/// to the general Morocco image, deliberately, because this app's users are
/// Moroccan and would spot a wrong landmark immediately. (The mockup's
/// original Casablanca photo was left out for exactly that reason: it
/// showed a European campanile, not the Hassan II mosque - the current
/// `hero_casablanca.jpg` is a verified replacement.)
class CityHeroHeader extends StatelessWidget {
  const CityHeroHeader({super.key, this.destination, this.trailing});

  final Airport? destination;

  /// Optional action shown opposite the headline (e.g. a notifications bell).
  final Widget? trailing;

  static const _cityImages = <String, String>{
    'FEZ': 'assets/images/hero_fes.jpg',
    'CMN': 'assets/images/hero_casablanca.jpg',
    'RAK': 'assets/images/hero_marrakech.jpg',
  };

  static const _defaultImage = 'assets/images/hero_morocco.jpg';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final t = localizations.t;
    final image = _cityImages[destination?.code] ?? _defaultImage;
    final city = destination?.city ?? t('heroDefaultDestination');

    // On a wide desktop/tablet browser the header would otherwise stretch
    // edge to edge while staying a fixed height - an extremely wide, short
    // band that BoxFit.cover can only fill by cropping the photo down
    // to a barely-recognizable sliver. Capping the photo itself to the same
    // width as the content below (matching ResponsiveBody) and filling the
    // rest with a plain navy band keeps the photo's actual composition
    // intact instead of destroying it for anyone not on a phone-width
    // viewport.
    return SizedBox(
      height: 340,
      child: ColoredBox(
        color: AppColors.heroNavy,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  image,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.25),
                  // A plain navy block is a perfectly good header on its own, so a
                  // missing or slow image degrades to that rather than to a gap.
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: AppColors.heroNavy),
                ),
                // Darkest at the top, where the status bar and headline sit, and
                // again at the very bottom so the search card below reads as
                // resting on the photo rather than colliding with it.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xE00B1B2E),
                        Color(0x8C0B1B2E),
                        Color(0x260B1B2E),
                        Color(0x590B1B2E),
                      ],
                      stops: [0, 0.3, 0.62, 1],
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.1,
                      colors: [Color(0x00000000), Color(0x59040A14)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _Headline(
                                greeting: t('heroGreeting'),
                                prefix: t('heroHeadlinePrefix'),
                                city: city)),
                        if (trailing != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline(
      {required this.greeting, required this.prefix, required this.city});

  final String greeting;
  final String prefix;
  final String city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 1,
              color: AppColors.heroGold.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                greeting.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.heroGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // The destination is the one word that changes as the user picks a
        // city, so it carries the gold while the rest stays white.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$prefix '),
              TextSpan(
                text: city,
                style: const TextStyle(color: AppColors.heroGold),
              ),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.25,
            shadows: const [
              Shadow(
                  color: Color(0x40000000),
                  blurRadius: 16,
                  offset: Offset(0, 2))
            ],
          ),
        ),
      ],
    );
  }
}
