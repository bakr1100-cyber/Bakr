import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/responsive_body.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final prefsProvider = context.watch<PreferencesProvider>();
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                leading: CircleAvatar(
                  backgroundColor: AppColors.moroccoGreen.withValues(alpha: 0.18),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                title: Text(t('yourTravelPreferences')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _SectionLabel(t('languageSectionLabel')),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: RadioGroup<AppLanguage>(
                groupValue: localeProvider.language,
                onChanged: (value) {
                  if (value != null) localeProvider.setLanguage(value);
                },
                child: Column(
                  children: [
                    for (final language in AppLanguage.values)
                      RadioListTile<AppLanguage>(
                        title: Text('${language.flagEmoji}  ${language.nativeName}'),
                        value: language,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _SectionLabel(t('appearanceSectionLabel')),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: RadioGroup<ThemeMode>(
                groupValue: themeProvider.mode,
                onChanged: (value) {
                  if (value != null) themeProvider.setMode(value);
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text(t('systemDefault')),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(t('lightMode')),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(t('darkMode')),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _SectionLabel(t('aiVoiceSectionLabel')),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: RadioGroup<bool>(
                groupValue: prefsProvider.preferences.preferredVoiceIsFemale,
                onChanged: (value) {
                  if (value != null) {
                    prefsProvider.update((p) => p.copyWith(preferredVoiceIsFemale: value));
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<bool>(title: Text(t('femaleVoice')), value: true),
                    RadioListTile<bool>(title: Text(t('maleVoice')), value: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
