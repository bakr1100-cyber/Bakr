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
    this.overlayOpacity = 0.48,
  });

  final Widget child;

  /// How dark the navy wash over the photo is. Lowered from an initial
  /// 0.74 per direct feedback - the photo needs to read clearly enough
  /// that a traveller recognizes which city it actually is, not just a
  /// dark, generic wash. Every screen using this already sets its own text
  /// white (see LanguageSelectScreen/ModeSelectScreen), so nothing depends
  /// on the wash staying dark for legibility.
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
