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
  late final Animation<double> _contentFade;
  late final Animation<double> _contentScale;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    // Exact timing per explicit request: 4 seconds total - 2 growing
    // (small -> an overshoot past full size), 1 holding at that big size,
    // then 1 shrinking back down to rest at full size before advancing. A
    // TweenSequence gives that three-phase split precisely (weights 2:1:1
    // out of a 4000ms controller - the middle phase is a flat hold, begin
    // == end) rather than leaving the shape of the motion to a single
    // curve.
    //
    // The logo and the "Tayarti" wordmark grow and shrink together as one
    // unit (per explicit correction - the wordmark previously faded in
    // late at a fixed size instead of growing with the logo, which made it
    // too easy to miss): both share this same scale animation instead of
    // the wordmark having its own.
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..forward();
    _contentFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.12, curve: Curves.easeOut));
    _contentScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.25, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 2,
      ),
      TweenSequenceItem(tween: ConstantTween(1.15), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_controller);
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Dominates the screen, per explicit request, while staying
                // provably within the viewport: the wordmark below adds
                // roughly another 36% of the logo's own height, so the logo
                // is capped off the *height* budget (not just the shorter
                // side) as well as the width, whichever is tighter - a
                // short/landscape viewport shrinks the logo instead of the
                // Column overflowing it.
                final available = constraints.biggest;
                final logoSize = [
                  available.height * 0.52,
                  available.width * 0.75,
                  480.0,
                ].reduce((a, b) => a < b ? a : b).clamp(120.0, 480.0);
                return FadeTransition(
                  opacity: _contentFade,
                  child: ScaleTransition(
                    scale: _contentScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppLogo(size: logoSize),
                        SizedBox(height: logoSize * 0.14),
                        Text(
                          'Tayarti',
                          style: TextStyle(
                            fontSize: logoSize * 0.22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(
                                  color: Color(0x66000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
