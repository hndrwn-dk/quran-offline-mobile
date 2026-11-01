import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The Mushaf rosette: two overlapping squares (0° and 45°) around a small
/// circle. [size] is the full extent (the 45° square's diagonal).
///
/// Shared by the framed sheet corners and the surah header, so both read as
/// one ornament. [fill] (usually the paper colour) hides lines running under it.
void paintMushafRosette(
  Canvas canvas,
  Offset center, {
  required double size,
  required Color stroke,
  double strokeWidth = 0.8,
  Color? fill,
}) {
  final half = size / 2;
  final side = size / math.sqrt2;
  final square = Rect.fromCenter(center: center, width: side, height: side);
  final diamond = Path()
    ..moveTo(center.dx, center.dy - half)
    ..lineTo(center.dx + half, center.dy)
    ..lineTo(center.dx, center.dy + half)
    ..lineTo(center.dx - half, center.dy)
    ..close();

  if (fill != null) {
    final fillPaint = Paint()..color = fill;
    canvas
      ..drawRect(square, fillPaint)
      ..drawPath(diamond, fillPaint);
  }

  final strokePaint = Paint()
    ..color = stroke
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..isAntiAlias = true;
  canvas
    ..drawRect(square, strokePaint)
    ..drawPath(diamond, strokePaint)
    ..drawCircle(center, size * 0.17, strokePaint);
}
