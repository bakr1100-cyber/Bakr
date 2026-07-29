import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/locale_provider.dart';
import '../assistant/ai_chat_screen.dart';
import '../home/home_screen.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
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
                'Wähle deine Sprache · اختر لغتك',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: ListView.separated(
                  itemCount: AppLanguage.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final language = AppLanguage.values[index];
                    return _LanguageOption(
                      language: language,
                      recommended: language == AppLanguage.ary,
                      onTap: () => _select(context, language),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, AppLanguage language) {
    context.read<LocaleProvider>().setLanguage(language);
    // Land on the normal tabbed home screen underneath, but push straight
    // into a voice-connected AI chat on top of it - the user only sees the
    // regular search/tabs screen once they press back from the assistant.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AiChatScreen(autoStartListening: true),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.recommended,
    required this.onTap,
  });

  final AppLanguage language;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: recommended
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: const BorderSide(color: AppColors.moroccoGold, width: 1.6),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.nativeName, style: theme.textTheme.titleLarge),
                    if (recommended) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Empfohlen für dich',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: AppColors.moroccoGold),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
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
