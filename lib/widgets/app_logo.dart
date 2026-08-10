import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The app's mark: a white airplane over a green five-pointed star, on the
/// Moroccan flag's red field - "Tayarti" (طيارتي, "my flight"), a plane and
/// the flag together, per explicit request. Matches `web/icons/` and
/// `web/favicon.png` (generated from the same design) so every in-app brand
/// moment and the browser/home-screen icon are the same mark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.moroccoRed,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size * 0.68, size * 0.68),
            painter: const _StarPainter(color: AppColors.flagGreen),
          ),
          Icon(Icons.flight_rounded, color: Colors.white, size: size * 0.42),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * 36 - 90) * (pi / 180);
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => oldDelegate.color != color;
}
