import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';

/// Per explicit user feedback: the button used to be red while idle and
/// green while listening - which is backwards from the near-universal
/// "record button turns red while recording" convention (camera apps,
/// voice memos), and was genuinely mistaken for the opposite. Listening is
/// now red (matching that convention) and idle is green; it also grows
/// larger and gently pulses while listening, so the state is unmistakable
/// even without reading the color at all.
class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  final bool isListening;
  final VoidCallback? onPressed;

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  static const _idleSize = 64.0;
  static const _listeningSize = 88.0;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _pulse = Tween<double>(begin: 1, end: 1.08).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );

  @override
  void didUpdateWidget(VoiceMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.isListening && !AppMotion.reduced(context)) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final size = widget.isListening ? _listeningSize : _idleSize;

    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: enabled ? 1 : 0.4,
      child: ScaleTransition(
        scale: _pulse,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isListening ? scheme.secondary : scheme.primary,
            boxShadow: widget.isListening
                ? [
                    BoxShadow(
                      color: scheme.secondary.withValues(alpha: 0.4),
                      blurRadius: 22,
                      spreadRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            tooltip: AppLocalizations.of(context)
                .t(widget.isListening ? 'stopVoiceInput' : 'startVoiceInput'),
            onPressed: widget.onPressed,
            icon: Icon(
              widget.isListening ? Icons.mic : Icons.mic_none_rounded,
              color: Colors.white,
              size: widget.isListening ? 36 : 28,
            ),
          ),
        ),
      ),
    );
  }
}
