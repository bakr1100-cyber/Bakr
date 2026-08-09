import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

/// A soft, looping shimmer sweep — wrap a stack of [SkeletonBlock]s in this
/// so a loading list reads as "content is arriving", not just an inert grey
/// placeholder.
class ShimmerLoader extends StatefulWidget {
  const ShimmerLoader({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
    if (AppMotion.reduced(context)) return widget.child;
    final base = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final dx = _controller.value * 3 - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 + dx, 0),
            end: Alignment(0.4 + dx, 0),
            colors: [
              base.withValues(alpha: 0.55),
              base.withValues(alpha: 1),
              base.withValues(alpha: 0.55),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Mimics [ItineraryCard]'s layout so the loading state doesn't jump/reflow
/// once real results arrive.
class ItineraryCardSkeleton extends StatelessWidget {
  const ItineraryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 96, height: 30),
            SizedBox(height: 8),
            SkeletonBlock(width: 140, height: 12),
            SizedBox(height: AppSpacing.lg),
            SkeletonBlock(width: double.infinity, height: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBlock(width: 200, height: 14),
            SizedBox(height: AppSpacing.md),
            SkeletonBlock(width: 160, height: 14),
          ],
        ),
      ),
    );
  }
}
