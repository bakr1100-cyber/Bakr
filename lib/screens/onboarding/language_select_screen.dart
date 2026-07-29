import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/big_button.dart';
import '../home/home_screen.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Row(
                children: [
                  Expanded(child: _FlagBar(color: AppColors.moroccoRed)),
                  Expanded(child: _FlagBar(color: AppColors.flagGreen)),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'MarocFly AI',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Wähle deine Sprache · اختر لغتك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: AppLanguage.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final language = AppLanguage.values[index];
                    return BigButton(
                      label: language.nativeName,
                      filled: language == AppLanguage.ary,
                      onPressed: () => _select(context, language),
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _FlagBar extends StatelessWidget {
  const _FlagBar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 6, color: color);
  }
}
