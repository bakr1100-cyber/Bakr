import 'dart:math';

import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/airport.dart';

/// The three verified photos (one that genuinely, unmistakably shows that
/// city - not a generic or mislabeled stand-in): the tiled Fès medina gate,
/// Casablanca's Hassan II mosque on the water, and Marrakech's Koutoubia
/// minaret.
const heroImages = <String>[
  'assets/images/hero_fes.jpg',
  'assets/images/hero_casablanca.jpg',
  'assets/images/hero_marrakech.jpg',
];

final _heroRandom = Random();

/// Rolls one of [heroImages] at random - per explicit request, every screen
/// with a photo header shows one of the three, independent of whatever
/// destination happens to be selected (most destinations have no verified
/// photo of their own anyway, so tying the photo to the destination meant
/// almost every screen fell back to the same generic image).
String randomHeroImage() => heroImages[_heroRandom.nextInt(heroImages.length)];

/// The photo-header frame shared by every screen that has one
/// ([CityHeroHeader], [RouteHeroHeader]): one of [heroImages] rolled at
/// random, capped to [ResponsiveBody]'s content width (so a wide
/// desktop/tablet browser doesn't force BoxFit.cover to crop the photo down
/// to a barely-recognizable sliver), the same night-blue wash over it, and
/// arbitrary foreground content on top.
///
/// The random pick is rolled once when this widget is first inserted into
/// the tree and then held for its lifetime (`late final` in [State]) - a
/// fresh roll on every rebuild would make the background flicker between
/// photos as the screen above it re-renders for unrelated reasons (typing a
/// date, ticking a counter). Navigating to the screen again mounts a new
/// instance and rolls again.
class HeroPhotoFrame extends StatefulWidget {
  const HeroPhotoFrame({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  State<HeroPhotoFrame> createState() => _HeroPhotoFrameState();
}

class _HeroPhotoFrameState extends State<HeroPhotoFrame> {
  late final String _image = randomHeroImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ColoredBox(
        color: AppColors.heroNavy,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _image,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.25),
                  // A plain navy block is a perfectly good header on its own,
                  // so a missing or slow image degrades to that rather than
                  // to a gap.
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: AppColors.heroNavy),
                ),
                // Darkest at the top, where the status bar and headline sit,
                // and again at the very bottom so whatever sits below reads
                // as resting on the photo rather than colliding with it -
                // lightened across the board per direct feedback: the photo
                // needs to read clearly enough to actually recognize the
                // city, not disappear under a dark wash.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xB00B1B2E),
                        Color(0x6E0B1B2E),
                        Color(0x1A0B1B2E),
                        Color(0x400B1B2E),
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
                      colors: [Color(0x00000000), Color(0x40040A14)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Photographic header for the search screen, from the design mockup: a
/// Moroccan skyline at dusk, a night-blue wash over it, and the headline
/// naming wherever the traveller is currently heading. See [randomHeroImage]
/// for how the photo itself is picked.
class CityHeroHeader extends StatelessWidget {
  const CityHeroHeader({super.key, this.destination, this.trailing});

  final Airport? destination;

  /// Optional action shown opposite the headline (e.g. a notifications bell).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final t = localizations.t;
    final city = destination?.city ?? t('heroDefaultDestination');

    return HeroPhotoFrame(
      height: 340,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Headline(
                  greeting: t('heroGreeting'),
                  prefix: t('heroHeadlinePrefix'),
                  city: city,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
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
