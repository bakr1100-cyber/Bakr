import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'city_hero_header.dart' show randomHeroImage;

/// A full-bleed photo behind a whole screen, for the screens a traveller
/// passes through before ever reaching an external booking site (splash,
/// language and mode pickers) - per explicit request, every one of them
/// should carry one of the three verified city photos, not just the search
/// screen's header band.
///
/// Rolls its photo once (see [randomHeroImage]) and holds it for the
/// widget's lifetime, same as [HeroPhotoFrame] - a fresh roll on every
/// rebuild would make the background flicker as the screen above
/// re-renders for unrelated reasons.
class FullScreenHeroBackground extends StatefulWidget {
  const FullScreenHeroBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.74,
  });

  final Widget child;

  /// How dark the navy wash over the photo is - high enough by default that
  /// plain dark-on-cream text (unchanged from the non-photo screens) stays
  /// legible without every caller having to re-color its own text white.
  final double overlayOpacity;

  @override
  State<FullScreenHeroBackground> createState() =>
      _FullScreenHeroBackgroundState();
}

class _FullScreenHeroBackgroundState extends State<FullScreenHeroBackground> {
  late final String _image = randomHeroImage();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: AppColors.heroNavy),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.heroNavy.withValues(alpha: widget.overlayOpacity),
          ),
        ),
        widget.child,
      ],
    );
  }
}
