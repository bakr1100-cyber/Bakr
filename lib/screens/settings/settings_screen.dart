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
          for (final language in AppLanguage.values)
            RadioListTile<AppLanguage>(
              title: Text(language.nativeName),
              value: language,
              groupValue: localeProvider.language,
              onChanged: (value) {
                if (value != null) localeProvider.setLanguage(value);
              },
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Erscheinungsbild', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Systemeinstellung'),
            value: ThemeMode.system,
            groupValue: themeProvider.mode,
            onChanged: (v) => themeProvider.setMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Hell'),
            value: ThemeMode.light,
            groupValue: themeProvider.mode,
            onChanged: (v) => themeProvider.setMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dunkel'),
            value: ThemeMode.dark,
            groupValue: themeProvider.mode,
            onChanged: (v) => themeProvider.setMode(v!),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Stimme des KI-Assistenten', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          RadioListTile<bool>(
            title: const Text('Weiblich'),
            value: true,
            groupValue: prefsProvider.preferences.preferredVoiceIsFemale,
            onChanged: (v) => prefsProvider.update(
              (p) => p.copyWith(preferredVoiceIsFemale: v),
            ),
          ),
          RadioListTile<bool>(
            title: const Text('Männlich'),
            value: false,
            groupValue: prefsProvider.preferences.preferredVoiceIsFemale,
            onChanged: (v) => prefsProvider.update(
              (p) => p.copyWith(preferredVoiceIsFemale: v),
            ),
          ),
        ],
      ),
    );
  }
}
