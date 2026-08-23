import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/full_screen_hero_background.dart';
import 'mode_select_screen.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      backgroundColor: AppColors.heroNavy,
      body: FullScreenHeroBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              // Caps the whole block's width BEFORE any stretch alignment
              // exists inside it - a stretch Column nested directly under a
              // loose parent forces its ConstrainedBox children to the full
              // incoming width instead of honoring their own maxWidth, which
              // is exactly what blew the language cards up to half the
              // screen each on a wide/tablet viewport.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 84),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      t('appName'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Wähle deine Sprache · اختر لغتك · Choisis ta langue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78)),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // A Wrap instead of a strict 2-column grid: with an odd
                    // number of languages, a GridView leaves the last card
                    // stuck on the left with empty space next to it - Wrap
                    // centers an incomplete last row instead.
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (var i = 0; i < AppLanguage.values.length; i++)
                          SizedBox(
                            width: 194,
                            height: 204,
                            child: _LanguageCard(
                              language: AppLanguage.values[i],
                              recommended:
                                  AppLanguage.values[i] == AppLanguage.ary,
                              entranceDelay: Duration(milliseconds: 80 * i),
                              onTap: () =>
                                  _select(context, AppLanguage.values[i]),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, AppLanguage language) {
    context.read<LocaleProvider>().setLanguage(language);
    context.read<ChatProvider>().setLanguage(language);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
    );
  }
}

/// One language tile - flag, native name, a small "speak this language"
/// icon, on a distinct brand gradient per card, with a soft fade+rise-in
/// entrance staggered by [entranceDelay] so the grid feels alive rather
/// than popping in all at once.
class _LanguageCard extends StatefulWidget {
  const _LanguageCard({
    required this.language,
    required this.recommended,
    required this.entranceDelay,
    required this.onTap,
  });

  final AppLanguage language;
  final bool recommended;
  final Duration entranceDelay;
  final VoidCallback onTap;

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(_fade);
  bool _pressed = false;

  static const _gradients = [
    AppGradients.primary,
    AppGradients.gold,
    AppGradients.accent,
    AppGradients.primaryDeep,
    // A fifth, distinct tone (deep red -> near-black) so the 5th language
    // card doesn't just repeat the first card's gradient.
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.redDark, Color(0xFF2A0A0C)],
    ),
  ];

  bool _startedAnimating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedAnimating) return;
    _startedAnimating = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    Future.delayed(widget.entranceDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[widget.language.index % _gradients.length];

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 120),
            // The shadow needs to sit outside the clip (clipping the
            // shadow-carrying decoration itself would cut the shadow off),
            // so it's painted one level up here, while the ClipRRect below
            // clips the gradient/content to a crisp rounded edge with no
            // sub-pixel bleed past the corners.
            child: DecoratedBox(
              decoration:
                  BoxDecoration(boxShadow: AppShadows.card(Colors.black)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    onTap: widget.onTap,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        border: widget.recommended
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.75),
                                width: 2)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          if (widget.recommended)
                            Positioned(
                              top: AppSpacing.sm,
                              right: AppSpacing.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)
                                      .t('recommendedForYou'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.language.flagEmoji,
                                    style: const TextStyle(fontSize: 44)),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  widget.language.nativeName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.record_voice_over_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
