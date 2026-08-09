import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';

class PassengerCounter extends StatelessWidget {
  const PassengerCounter({
    super.key,
    required this.count,
    required this.onChanged,
  });

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context).t;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: t('passengers'),
        prefixIcon: const Icon(Icons.people_alt_rounded),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundIconButton(
            icon: Icons.remove_rounded,
            enabled: count > 1,
            label: t('decreasePassengers'),
            onTap: () => onChanged(count - 1),
          ),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          _RoundIconButton(
            icon: Icons.add_rounded,
            enabled: count < 9,
            label: t('increasePassengers'),
            onTap: () => onChanged(count + 1),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: enabled ? AppColors.moroccoGreen.withValues(alpha: 0.16) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          // 44x44 is the accessibility-minimum touch target (was 40x40) -
          // the icon itself stays visually smaller, centered inside.
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
