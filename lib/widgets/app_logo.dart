import 'package:flutter/material.dart';

/// The app's mark: a minimalist green airplane trailing a gold star and
/// comet swoosh, on a near-black field, text-free - the "Tayarti"/"طيارتي"
/// wordmark is set separately wherever this appears (e.g.
/// [LanguageSelectScreen]), not baked into the image. Shown in-app exactly
/// as it is on the browser/home-screen icon (`web/icons/Icon-192.png` etc.)
/// - `assets/images/app_logo.png` is that same source image.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
      ),
    );
  }
}
