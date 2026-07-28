import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class VoiceMicButton extends StatelessWidget {
  const VoiceMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  final bool isListening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isListening ? scheme.primary : scheme.secondary,
        boxShadow: isListening
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          isListening ? Icons.mic : Icons.mic_none_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
