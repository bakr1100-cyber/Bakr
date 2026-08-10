import 'package:flutter/material.dart';

/// The app's mark: a climbing airliner in front of the Moroccan flag's
/// five-pointed star, on the flag's red field - "Tayarti" (طيارتي, "my
/// flight"), a plane and the flag together, per explicit request. The
/// artwork itself (gradients/shading/shadow for a dimensional look, not a
/// flat glyph) lives in `assets/images/app_logo.png`, generated from
/// `web/icons/Icon-512.png` so every in-app brand moment and the
/// browser/home-screen icon are the same mark.
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
