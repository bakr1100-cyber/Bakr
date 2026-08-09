import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Three softly bouncing dots inside an AI-styled bubble, shown while the
/// assistant is "thinking" — reads as alive, unlike a plain spinner.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _startedAnimating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedAnimating) return;
    _startedAnimating = true;
    if (!AppMotion.reduced(context)) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = (_controller.value - (i * 0.2)) % 1.0;
              final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.translate(
                  offset: Offset(0, -6 * bounce.clamp(0, 1)),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.moroccoGreen
                          .withValues(alpha: 0.5 + 0.5 * bounce.clamp(0, 1)),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
