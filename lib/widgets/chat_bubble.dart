import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatefulWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_fade);
  bool _startedAnimating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedAnimating) return;
    _startedAnimating = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.sender == ChatSender.user;
    final scheme = Theme.of(context).colorScheme;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [AppColors.greenLight, AppColors.moroccoGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUser ? null : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message.wasSpoken)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 16,
                color: isUser ? Colors.white70 : scheme.primary,
              ),
            ),
          Flexible(
            child: Text(
              widget.message.text,
              style: TextStyle(
                color: isUser ? Colors.white : scheme.onSurface,
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );

    final row = Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          const _AiAvatar(),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: bubble),
      ],
    );

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: row),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.greenLight, AppColors.moroccoGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
    );
  }
}
