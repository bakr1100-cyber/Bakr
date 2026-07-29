import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Premium, minimalist theme: very large tappable targets, fast implicit
/// animations everywhere (see [AppMotion]), and the Morocco flag palette
/// as the single accent across both brightness modes.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Seed a full Material 3 tonal palette from the brand green so every
    // derived surface/container token (nav bar, chips, containers) comes out
    // tinted green instead of falling back to Flutter's neutral grey/white
    // defaults, then pin the exact brand hues on top of it.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.moroccoGreen,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.moroccoGreen,
      onPrimary: AppColors.moroccoWhite,
      secondary: AppColors.moroccoRed,
      onSecondary: AppColors.moroccoWhite,
      tertiary: AppColors.moroccoGold,
      onTertiary: AppColors.lightOnSurface,
      error: AppColors.danger,
      onError: AppColors.moroccoWhite,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
    );

    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.moroccoGreen,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.moroccoWhite,
        iconTheme: const IconThemeData(color: AppColors.moroccoWhite),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.moroccoWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.moroccoGreen,
        indicatorColor: isDark
            ? AppColors.greenDark
            : AppColors.moroccoWhite.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? (states.contains(WidgetState.selected)
                    ? AppColors.moroccoGreen
                    : AppColors.darkSubtle)
                : AppColors.moroccoWhite,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: isDark
                ? (states.contains(WidgetState.selected)
                    ? AppColors.moroccoGreen
                    : AppColors.darkSubtle)
                : AppColors.moroccoWhite,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          backgroundColor: AppColors.moroccoGreen,
          foregroundColor: AppColors.moroccoWhite,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          backgroundColor: AppColors.greenDark,
          foregroundColor: AppColors.moroccoWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

/// Central place for animation durations/curves so every transition in the
/// app feels equally snappy, per the "sehr schnelle Animationen" requirement.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 240);
  static const Curve curve = Curves.easeOutCubic;
}
