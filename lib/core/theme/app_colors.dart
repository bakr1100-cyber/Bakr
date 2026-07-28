import 'package:flutter/material.dart';

/// Palette drawn from the Moroccan flag: red field, green pentagram, white.
class AppColors {
  AppColors._();

  static const Color moroccoRed = Color(0xFFC1272D);
  static const Color moroccoGreen = Color(0xFF006233);
  static const Color moroccoWhite = Color(0xFFFFFFFF);

  static const Color redDark = Color(0xFF8E1B21);
  static const Color greenDark = Color(0xFF00431F);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightSubtle = Color(0xFF6B6B6B);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFF2F2F2);
  static const Color darkSubtle = Color(0xFFAFAFAF);

  static const Color success = moroccoGreen;
  static const Color danger = moroccoRed;
  static const Color warning = Color(0xFFE0A500);
}
