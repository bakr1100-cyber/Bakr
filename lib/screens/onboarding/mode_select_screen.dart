import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/home_navigation_provider.dart';
import '../../widgets/app_logo.dart';
import '../home/home_screen.dart';

/// Shown once, right after picking a language: "KI-Modus oder normale
/// Version?" - per explicit request, this is a first-class choice made
/// before landing in the app, not something buried behind a tab. Either
/// choice still lands on the same [HomeScreen] with its full bottom nav -
/// this only picks which tab shows first, so switching between the two
/// ways of searching stays one tap away afterwards either way.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 64),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    t('modeSelectTitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t('modeSelectSubtitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _ModeCard(
                    icon: Icons.auto_awesome_rounded,
                    title: t('modeAiTitle'),
                    subtitle: t('modeAiSubtitle'),
                    gradient: AppGradients.primaryDeep,
                    tint: AppColors.moroccoGreen,
                    onTap: () => _enter(context, HomeNavigationProvider.assistantTabIndex),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ModeCard(
                    icon: Icons.search_rounded,
                    title: t('modeClassicTitle'),
                    subtitle: t('modeClassicSubtitle'),
                    gradient: AppGradients.accent,
                    tint: AppColors.moroccoRed,
                    onTap: () => _enter(context, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enter(BuildContext context, int tabIndex) {
    context.read<HomeNavigationProvider>().goToTab(tabIndex);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card(tint),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
