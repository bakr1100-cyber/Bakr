import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Premium, minimalist theme: very large tappable targets, fast implicit
/// animations everywhere (see [AppMotion]), and the Fès-Smaragd palette
/// carried through every surface, container and text token — never a
/// fallback to Flutter's neutral grey/white.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final subtle = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final canvas = isDark ? AppColors.darkBackground : AppColors.lightBackground;

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
      primaryContainer: AppColors.greenDark,
      // primaryContainer/tertiary are fixed dark-green/gold fills in both
      // themes, so their "on" text always needs to be light - reuse
      // darkOnSurface (near-white) rather than lightOnSurface, which is
      // now a dark charcoal meant for text on the light theme's own
      // (cream) surfaces, not for text on top of a colored fill.
      onPrimaryContainer: AppColors.darkOnSurface,
      secondary: AppColors.moroccoRed,
      onSecondary: AppColors.moroccoWhite,
      secondaryContainer: AppColors.redDark,
      onSecondaryContainer: AppColors.moroccoWhite,
      tertiary: AppColors.moroccoGold,
      onTertiary: AppColors.darkOnSurface,
      error: AppColors.danger,
      onError: AppColors.moroccoWhite,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: subtle,
      outline: subtle,
      outlineVariant: subtle.withValues(alpha: 0.4),
      shadow: Colors.black,
      scrim: Colors.black,
      // Every M3 "container" tier defaults to a pale neutral tone even when
      // seeded from a saturated color — Chips, BottomSheets, menus, dialogs,
      // etc. all pull from these, so pin them to our own surfaces or they
      // render white.
      surfaceContainerLowest: canvas,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,
    );

    // Type pairing: Plus Jakarta Sans for anything headline-sized (carries
    // the brand's personality), Inter for body/label copy (quiet workhorse
    // for dense flight data). Both re-colored onto the green canvas since
    // Flutter's default text themes assume a light/white background.
    final baseTextTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final display = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
    final body = GoogleFonts.interTextTheme(baseTextTheme);

    final textTheme = TextTheme(
      displayLarge:
          display.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
      displayMedium:
          display.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displaySmall:
          display.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineLarge:
          display.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineMedium:
          display.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall:
          display.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: display.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.4),
      bodySmall: body.bodySmall?.copyWith(height: 1.35),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.1),
      labelMedium:
          body.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall:
          body.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _PremiumPageTransitionsBuilder(),
          TargetPlatform.iOS: _PremiumPageTransitionsBuilder(),
          TargetPlatform.macOS: _PremiumPageTransitionsBuilder(),
          TargetPlatform.windows: _PremiumPageTransitionsBuilder(),
          TargetPlatform.linux: _PremiumPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.moroccoGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        centerTitle: false,
        foregroundColor: AppColors.moroccoWhite,
        iconTheme: const IconThemeData(color: AppColors.moroccoWhite),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.moroccoWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.moroccoGreen,
        indicatorColor: isDark
            ? AppColors.greenDark
            : AppColors.moroccoWhite.withValues(alpha: 0.22),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
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
          backgroundColor: AppColors.moroccoRed,
          foregroundColor: AppColors.moroccoWhite,
          disabledBackgroundColor: surface,
          disabledForegroundColor: subtle,
          elevation: 8,
          shadowColor: AppColors.moroccoRed.withValues(alpha: 0.5),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          backgroundColor: AppColors.greenDark,
          foregroundColor: AppColors.moroccoWhite,
          elevation: 6,
          shadowColor: AppColors.moroccoGreen.withValues(alpha: 0.4),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: AppColors.moroccoGreen,
          side: BorderSide(color: AppColors.moroccoGreen.withValues(alpha: 0.6), width: 1.4),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: subtle),
        hintStyle: TextStyle(color: subtle),
        floatingLabelStyle: const TextStyle(color: AppColors.moroccoGreen, fontWeight: FontWeight.w700),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.moroccoGreen, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.moroccoGreen,
        disabledColor: surface.withValues(alpha: 0.5),
        labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 13),
        secondaryLabelStyle: const TextStyle(
            color: AppColors.moroccoWhite, fontWeight: FontWeight.w700, fontSize: 13),
        side: BorderSide(color: subtle.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: subtle,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.moroccoGreen,
        headerForegroundColor: AppColors.moroccoWhite,
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.moroccoGreen),
        todayBorder: const BorderSide(color: AppColors.moroccoGreen),
        dayForegroundColor: WidgetStatePropertyAll(onSurface),
        yearForegroundColor: WidgetStatePropertyAll(onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.greenDark,
        contentTextStyle: const TextStyle(color: AppColors.moroccoWhite, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dividerTheme: DividerThemeData(color: subtle.withValues(alpha: 0.25), thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: onSurface,
        textColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}

/// A quiet fade + gentle upward slide used for every push/pop across the
/// app, on every platform — replaces the default abrupt Android zoom /
/// Cupertino full-slide with something calmer that reads as "premium".
class _PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const _PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

/// Central place for animation durations/curves so every transition in the
/// app feels equally snappy, per the "sehr schnelle Animationen" requirement.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
  static const Curve curve = Curves.easeOutCubic;

  /// True when the platform's "reduce motion" accessibility setting is on
  /// (iOS Reduce Motion, Android "remove animations", or the equivalent
  /// browser/OS setting on web) - decorative/looping animations (typing
  /// dots, shimmer, entrance slides) should skip straight to their end
  /// state instead of animating when this is true.
  static bool reduced(BuildContext context) => MediaQuery.of(context).disableAnimations;
}
