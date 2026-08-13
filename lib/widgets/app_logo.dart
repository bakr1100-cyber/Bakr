import 'package:flutter/material.dart';

/// The app's mark: a climbing airliner in front of the Moroccan flag's
/// five-pointed star, on the flag's red field - "Tayarti" (طيارتي, "my
/// flight"), a plane and the flag together, per explicit request. The
/// artwork in `assets/images/app_logo.png` is a text-free crop of the
/// browser/home-screen icon (`web/icons/Icon-192.png` etc., which carries
/// the "Tayarti" wordmark baked in) - no wordmark here since this widget
/// sits next to a separately localized name (e.g. "طيارتي" in Arabic UI),
/// where baked-in Latin text would be wrong.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png',
      width: size,
      height: size,
    );
  }
}
