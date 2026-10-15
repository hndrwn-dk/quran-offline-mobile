import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Eight-point star medal with the ayah number in the middle.
class VerseStarMedal extends StatelessWidget {
  const VerseStarMedal({
    super.key,
    required this.ayahNo,
    this.size = 44,
  });

  final int ayahNo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarMedalPainter(color: colorScheme.primary),
        child: Center(
          child: Text(
            '$ayahNo',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
          ),
        ),
      ),
    );
  }
}

class _StarMedalPainter extends CustomPainter {
  const _StarMedalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final inner = outer * 0.72;
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final point = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarMedalPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
