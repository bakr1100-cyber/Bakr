import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The app's mark: a minimalist green airplane trailing a gold star and
/// comet swoosh, on a near-black field, text-free - the "Tayarti"/"طيارتي"
/// wordmark is set separately wherever this appears (e.g.
/// [LanguageSelectScreen]), not baked into the image. Shown in-app exactly
/// as it is on the browser/home-screen icon (`web/icons/Icon-192.png` etc.)
/// - `assets/images/app_logo.png` is that same source image.
///
/// The image's own field is near-black (RGB ~5,14,15) - fine over a light
/// or mid-tone background, but on the dark navy full-screen photo
/// backgrounds ([FullScreenHeroBackground], used on the splash and the
/// language/mode pickers) the logo all but disappears into it. A soft gold
/// glow behind the shape keeps it visible regardless of what's behind it,
/// rather than only working by coincidence depending on the calling
/// screen's own background.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroGold.withValues(alpha: 0.5),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.02,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
        ),
      ),
    );
  }
}
