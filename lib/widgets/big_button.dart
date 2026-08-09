import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

/// Very large, thumb-friendly primary action button — core to the "maximal
/// drei Klicks bis zur Flugsuche" and "sehr große Buttons" requirements.
/// Renders as a soft gradient pill with a gentle press-scale micro-
/// interaction instead of a flat Material button, so the one or two most
/// important taps per screen always feel deliberately premium.
class BigButton extends StatefulWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// `false` (default): the red gradient — used for the single most
  /// important action on a screen (e.g. "Flüge suchen").
  /// `true`: the deep-green gradient — used for the secondary emphasized
  /// action (e.g. "Reisebegleiter aktivieren").
  final bool filled;

  /// Shows a spinner in place of the icon/label and blocks taps - use while
  /// the action this button triggers is in flight, so a slow connection
  /// can't be mistaken for a dead button and doesn't invite a double-tap
  /// that fires the action twice.
  final bool loading;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final gradient = widget.filled ? AppGradients.primaryDeep : AppGradients.accent;
    final tint = widget.filled ? AppColors.moroccoGreen : AppColors.moroccoRed;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: AnimatedOpacity(
          opacity: widget.onPressed == null && !widget.loading ? 0.45 : 1,
          duration: AppMotion.fast,
          child: Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: enabled ? AppShadows.button(tint) : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: enabled ? widget.onPressed : null,
                child: widget.loading
                    ? const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(AppColors.moroccoWhite),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 24, color: AppColors.moroccoWhite),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: AppColors.moroccoWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
