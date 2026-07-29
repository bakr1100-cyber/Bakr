import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/locale_provider.dart';
import '../home/home_screen.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.travel_explore_rounded,
                        size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Center(
                  child: _FlagPill(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'MarocFly AI',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Wähle deine Sprache · اختر لغتك · Choisis ta langue',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.95,
                    children: [
                      for (var i = 0; i < AppLanguage.values.length; i++)
                        _LanguageCard(
                          language: AppLanguage.values[i],
                          recommended: AppLanguage.values[i] == AppLanguage.ary,
                          entranceDelay: Duration(milliseconds: 80 * i),
                          onTap: () => _select(context, AppLanguage.values[i]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, AppLanguage language) {
    context.read<LocaleProvider>().setLanguage(language);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
  ];

  @override
  void initState() {
    super.initState();
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                onTap: widget.onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: widget.recommended
                        ? Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2)
                        : null,
                    boxShadow: AppShadows.card(Colors.black),
                  ),
                  child: Stack(
                    children: [
                      if (widget.recommended)
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              AppLocalizations.of(context).t('recommendedForYou'),
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
                            Text(widget.language.flagEmoji, style: const TextStyle(fontSize: 44)),
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
    );
  }
}

class _FlagPill extends StatelessWidget {
  const _FlagPill();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: const SizedBox(
        width: 64,
        height: 5,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: AppColors.moroccoRed)),
            Expanded(child: ColoredBox(color: AppColors.flagGreen)),
          ],
        ),
      ),
    );
  }
}
