import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/full_screen_hero_background.dart';
import 'language_select_screen.dart';

/// The very first thing a traveller sees: the app mark settling onto the
/// same night skyline used on the search screen's header, so the brand
/// identity carries straight through from launch into the app itself
/// instead of a generic loading spinner.
///
/// Auto-advances to [LanguageSelectScreen] once the entrance animation
/// finishes (or immediately on reduced-motion) - a tap skips it outright,
/// since a splash that can't be skipped is just an obstacle on every
/// repeat launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow * 2)
      ..forward();
    _logoFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _logoScale = Tween(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.7, curve: Curves.easeOutBack)),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _advance();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) _advance();
  }

  void _advance() {
    if (_advanced || !mounted) return;
    _advanced = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LanguageSelectScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroNavy,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: FullScreenHeroBackground(
          child: Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: const AppLogo(size: 132),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
