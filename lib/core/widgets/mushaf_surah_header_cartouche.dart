import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Open end-caps for the surah header: two ornamental brackets ﴾ ﴿ that sit
/// beside the name, opening toward it. No closed outline, no hairlines — the
/// glyph keeps its full ink size and nothing is drawn above or below it.
@immutable
class MushafEndCapsGeometry {
  const MushafEndCapsGeometry({
    required this.leftCap,
    required this.rightCap,
    required this.strokeWidth,
    required this.innerStrokeWidth,
    required this.dotRadius,
    required this.innerInset,
  });

  final Rect leftCap;
  final Rect rightCap;
  final double strokeWidth;
  final double innerStrokeWidth;
  final double dotRadius;
  final double innerInset;

  @override
  bool operator ==(Object other) =>
      other is MushafEndCapsGeometry &&
      other.leftCap == leftCap &&
      other.rightCap == rightCap &&
      other.strokeWidth == strokeWidth &&
      other.innerStrokeWidth == innerStrokeWidth &&
      other.dotRadius == dotRadius &&
      other.innerInset == innerInset;

  @override
  int get hashCode => Object.hash(
        leftCap,
        rightCap,
        strokeWidth,
        innerStrokeWidth,
        dotRadius,
        innerInset,
      );
}

/// Gap between the name ink and the inner arc, as a share of the row height.
const double kMushafEndCapGap = 0.6;

/// Minimum gap relative to the glyph ink height.
const double kMushafEndCapGapInk = 0.55;

/// Cap height, as a share of the row height.
const double kMushafEndCapHeight = 0.9;

/// Cap height relative to the glyph ink height (1.0-1.1x).
const double kMushafEndCapHeightInk = 1.05;

/// Reference strokes in page-layout units (scaled with the frame).
/// At the 933x704 spread (~1.235x) these render ~1.0dp and ~0.5dp.
const double kMushafEndCapStroke = 0.81;
const double kMushafEndCapInnerStroke = 0.405;

const double _capWidthFactor = 0.34;
const double _innerInset = 3.2;
const double _dotRadius = 1.4;

MushafEndCapsGeometry layoutMushafEndCaps({
  required Size box,
  required Rect inkRect,
  double? rowPitch,
}) {
  final pitch = rowPitch ?? box.height;
  final capHeight = math.max(pitch * kMushafEndCapHeight,
          inkRect.height * kMushafEndCapHeightInk)
      .clamp(0.0, box.height);
  final capWidth = math.max(2.0, capHeight * _capWidthFactor);
  final gap = math.max(pitch * kMushafEndCapGap,
      inkRect.height * kMushafEndCapGapInk);
  final centerY = inkRect.center.dy;

  var top = centerY - capHeight / 2;
  top = top.clamp(0.0, math.max(0.0, box.height - capHeight));

  var leftX = inkRect.left - gap - capWidth;
  leftX = leftX.clamp(1.0, math.max(1.0, box.width - 2 * capWidth - 2));
  var rightX = inkRect.right + gap;
  rightX = math.min(rightX, box.width - capWidth - 1);

  return MushafEndCapsGeometry(
    leftCap: Rect.fromLTWH(leftX, top, capWidth, capHeight),
    rightCap: Rect.fromLTWH(rightX, top, capWidth, capHeight),
    strokeWidth: kMushafEndCapStroke,
    innerStrokeWidth: kMushafEndCapInnerStroke,
    dotRadius: _dotRadius,
    innerInset: _innerInset,
  );
}

/// A single bracket arc. [openingRight] means the arc bulges left and its tips
/// point right (the left cap of a name).
Path mushafEndCapPath(
  Rect rect, {
  required bool openingRight,
  double inset = 0,
}) {
  final r = Rect.fromLTWH(
    rect.left + (openingRight ? inset * 0.35 : 0),
    rect.top + inset,
    rect.width - inset * 0.35,
    math.max(0.0, rect.height - inset * 2),
  );
  if (r.height <= 0 || r.width <= 0) return Path();

  final xTip = openingRight ? r.right : r.left;
  final xBulge = openingRight ? r.left : r.right;
  final dx = xTip - xBulge;

  final path = Path()
    // Slightly pointed tips: a short hook past each end, butt-capped.
    ..moveTo(xTip + (openingRight ? -1.4 : 1.4), r.top - 0.8)
    ..lineTo(xTip, r.top)
    ..cubicTo(
      xTip - dx * 0.55,
      r.top + r.height * 0.12,
      xBulge,
      r.top + r.height * 0.30,
      xBulge,
      r.center.dy,
    )
    ..cubicTo(
      xBulge,
      r.bottom - r.height * 0.30,
      xTip - dx * 0.55,
      r.bottom - r.height * 0.12,
      xTip,
      r.bottom,
    )
    ..lineTo(xTip + (openingRight ? -1.4 : 1.4), r.bottom + 0.8);
  return path;
}

class MushafSurahEndCapsPainter extends CustomPainter {
  const MushafSurahEndCapsPainter({
    required this.geometry,
    required this.color,
  });

  final MushafEndCapsGeometry geometry;
  final Color color;

  static Paint outerPaint(Color color, MushafEndCapsGeometry geometry) {
    return Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = outerPaint(color, geometry);
    final inner = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.innerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final cap in [geometry.leftCap, geometry.rightCap]) {
      final openingRight = cap == geometry.leftCap;
      canvas.drawPath(
        mushafEndCapPath(cap, openingRight: openingRight),
        outer,
      );
      canvas.drawPath(
        mushafEndCapPath(
          cap,
          openingRight: openingRight,
          inset: geometry.innerInset,
        ),
        inner,
      );
      // Small dot at the outer tip.
      final tip = Offset(
        openingRight ? cap.left : cap.right,
        cap.center.dy,
      );
      canvas.drawCircle(
        tip,
        geometry.dotRadius,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(MushafSurahEndCapsPainter oldDelegate) {
    return oldDelegate.geometry != geometry || oldDelegate.color != color;
  }
}

/// End-caps drawn over an existing (1.0.21+69) glyph without touching it.
class MushafSurahEndCapsOverlay extends StatelessWidget {
  const MushafSurahEndCapsOverlay({
    super.key,
    required this.box,
    required this.inkRect,
    required this.color,
    this.rowPitch,
  });

  final Size box;
  final Rect inkRect;
  final Color color;
  final double? rowPitch;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: MushafSurahEndCapsPainter(
          geometry: layoutMushafEndCaps(box: box, inkRect: inkRect, rowPitch: rowPitch),
          color: color,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}



