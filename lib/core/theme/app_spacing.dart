import 'package:flutter/material.dart';

/// A single 4px-based spacing scale used everywhere instead of ad-hoc
/// magic-number `SizedBox`/`EdgeInsets` values, so rhythm stays consistent
/// across every screen.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;
}

/// Corner radii — one scale for the whole app so cards, buttons, chips and
/// sheets all feel like the same family of shapes.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// Soft, colored elevation shadows (never a flat grey drop-shadow) so raised
/// surfaces read as lifted off the green canvas rather than just outlined.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> button(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.45),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> floating(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];
}
