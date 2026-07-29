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
  static const Color greenDark = Color(0xFF066455);

  // Light theme surfaces — visibly green-tinted, never flat white.
  static const Color lightBackground = Color(0xFFDFF2EC);
  static const Color lightSurface = Color(0xFFF3FBF8);
  static const Color lightOnSurface = Color(0xFF0B2620);
  static const Color lightSubtle = Color(0xFF5B7A72);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF08201B);
  static const Color darkSurface = Color(0xFF102822);
  static const Color darkOnSurface = Color(0xFFDEF5EE);
  static const Color darkSubtle = Color(0xFF7FC7B6);

  static const Color success = moroccoGreen;
  static const Color danger = moroccoRed;
  static const Color warning = moroccoGold;
}
