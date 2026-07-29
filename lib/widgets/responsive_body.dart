import 'package:flutter/material.dart';

/// Caps content width and centers it on wide viewports (desktop/tablet
/// browser) so a mobile-first layout doesn't stretch edge to edge, while
/// leaving the app bar / bottom nav (owned by each screen's own [Scaffold])
/// full width as normal chrome.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
