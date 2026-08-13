import 'package:flutter/material.dart';

/// The app's mark: a climbing airliner in front of the Moroccan flag's
/// five-pointed star, on the flag's red field, with the "Tayarti" wordmark
/// baked in - per explicit request, shown in-app exactly as it is on the
/// browser/home-screen icon (`web/icons/Icon-192.png` etc.), not a
/// text-free variant. `assets/images/app_logo.png` is that same source
/// image, cropped to drop its pre-baked rounded corners/border (which
/// would show as a stray white square on non-white app backgrounds, since
/// the source PNG has no alpha channel) and composited onto a full-bleed
/// flag-red backing.
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
