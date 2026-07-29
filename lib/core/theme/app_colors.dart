import 'package:flutter/material.dart';

/// "Fès-Smaragd": a saturated teal-emerald (blend of Fès riad-roof turquoise
/// and jewel emerald) as the brand accent, with the Moroccan flag red kept
/// as a sparing accent and gold as a tertiary highlight.
class AppColors {
  AppColors._();

  static const Color moroccoRed = Color(0xFFC1272D);
  static const Color moroccoGreen = Color(0xFF00A88C);
  static const Color moroccoWhite = Color(0xFFFFFFFF);
  static const Color moroccoGold = Color(0xFFDEB44C);

  /// True Moroccan flag green — only for rendering the actual flag, not the
  /// app's UI accent (see [moroccoGreen] for that).
  static const Color flagGreen = Color(0xFF006233);

  static const Color redDark = Color(0xFF8E1B21);
  static const Color redLight = Color(0xFFE2565D);
  static const Color greenDark = Color(0xFF066455);
  static const Color greenLight = Color(0xFF3FD6BC);

  // Light theme surfaces — a neutral, near-charcoal canvas (just a whisper
  // of green, never flat white), so red/green/gold accents on top of it
  // actually stand out instead of everything reading as "all green".
  static const Color lightBackground = Color(0xFF11201C);
  static const Color lightSurface = Color(0xFF1A2925);
  static const Color lightOnSurface = Color(0xFFF3FBF8);
  static const Color lightSubtle = Color(0xFFA6BDB5);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF08201B);
  static const Color darkSurface = Color(0xFF102822);
  static const Color darkOnSurface = Color(0xFFDEF5EE);
  static const Color darkSubtle = Color(0xFF7FC7B6);

  static const Color success = moroccoGreen;
  static const Color danger = moroccoRed;
  static const Color warning = moroccoGold;
}

/// Reusable gradients — every hero surface (app bar, primary CTA, price
/// header) draws from this small, consistent set instead of one-off colors.
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.greenLight, AppColors.moroccoGreen],
  );

  static const LinearGradient primaryDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.moroccoGreen, AppColors.greenDark],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.redLight, AppColors.moroccoRed],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.moroccoGold, Color(0xFFC98F2A)],
  );

  static const LinearGradient canvas = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.greenDark, AppColors.lightBackground],
  );
}
