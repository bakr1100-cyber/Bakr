import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/theme_provider.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final prefsProvider = context.watch<PreferencesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Deine Reisevorlieben'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Sprache', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          RadioGroup<AppLanguage>(
            groupValue: localeProvider.language,
            onChanged: (value) {
              if (value != null) localeProvider.setLanguage(value);
            },
            child: Column(
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    title: Text(language.nativeName),
                    value: language,
                  ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Erscheinungsbild', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          RadioGroup<ThemeMode>(
            groupValue: themeProvider.mode,
            onChanged: (value) {
              if (value != null) themeProvider.setMode(value);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('Systemeinstellung'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Hell'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dunkel'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Stimme des KI-Assistenten', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          RadioGroup<bool>(
            groupValue: prefsProvider.preferences.preferredVoiceIsFemale,
            onChanged: (value) {
              if (value != null) {
                prefsProvider.update((p) => p.copyWith(preferredVoiceIsFemale: value));
              }
            },
            child: const Column(
              children: [
                RadioListTile<bool>(title: Text('Weiblich'), value: true),
                RadioListTile<bool>(title: Text('Männlich'), value: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
