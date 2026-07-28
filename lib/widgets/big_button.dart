import 'package:flutter/material.dart';

/// Very large, thumb-friendly primary action button - core to the "maximal
/// drei Klicks bis zur Flugsuche" and "sehr große Buttons" requirements.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 24),
          const SizedBox(width: 12),
        ],
        Text(label),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton(onPressed: onPressed, child: child)
          : ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}
