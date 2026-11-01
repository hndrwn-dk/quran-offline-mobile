import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Option-I surah header cartouche: a thin, single-colour ogee outline around
/// the surah-name ink with one hairline per side. No fill, no tint — the lines
/// use the same colour as the Mushaf text at 50% opacity so light/dark/sepia
/// follow the theme automatically.
@immutable
class MushafCartoucheGeometry {
  const MushafCartoucheGeometry({
    required this.cartouche,
    required this.hairlines,
    required this.strokeWidth,
    required this.hairlineWidth,
  });

  final Rect cartouche;
  final List<(Offset, Offset)> hairlines;
  final double strokeWidth;
  final double hairlineWidth;

  @override
  bool operator ==(Object other) =>
      other is MushafCartoucheGeometry &&
      other.cartouche == cartouche &&
      other.strokeWidth == strokeWidth &&
      other.hairlineWidth == hairlineWidth &&
      _sameHairlines(other.hairlines, hairlines);

  @override
  int get hashCode => Object.hash(cartouche, strokeWidth, hairlineWidth,
      hairlines.length, hairlines.isEmpty ? null : hairlines.first);

  static bool _sameHairlines(
    List<(Offset, Offset)> a,
    List<(Offset, Offset)> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].$1 != b[i].$1 || a[i].$2 != b[i].$2) return false;
    }
    return true;
  }
}

/// Cartouche width padding per side, as a share of the row height.
const double kMushafCartoucheSidePadding = 0.6;

/// Minimum cartouche width, as a share of the row height.
const double kMushafCartoucheMinWidth = 2.4;

/// Reference stroke widths in page-layout units. The whole page is scaled into
/// its frame, so at the 933x704 spread (~1.235x) these render ~0.9dp / ~0.6dp.
const double kMushafCartoucheStroke = 0.73;
const double kMushafCartoucheHairline = 0.49;

/// Builds the cartouche around [inkRect] inside a [box] of pageWidth x rowHeight.
///
/// The outline keeps a little breathing room around the ink and never leaves
/// the row; the side hairlines run from the tips to 4% before the page edge.
MushafCartoucheGeometry layoutMushafCartouche({
  required Size box,
  required Rect inkRect,
  double strokeWidth = kMushafCartoucheStroke,
  double hairlineWidth = kMushafCartoucheHairline,
}) {
  final rowHeight = box.height;
  final padX = rowHeight * kMushafCartoucheSidePadding;
  final maxWidth = box.width * 0.86;
  final targetWidth = math.max(
    inkRect.width + padX * 2,
    math.min(rowHeight * kMushafCartoucheMinWidth, maxWidth),
  );
  final width = targetWidth.clamp(0.0, maxWidth).toDouble();
  final height = math
      .max(inkRect.height + rowHeight * 0.04, rowHeight * 0.5)
      .clamp(0.0, math.max(0.0, rowHeight - strokeWidth * 2))
      .toDouble();

  final rect = Rect.fromCenter(
    center: inkRect.center,
    width: width,
    height: height,
  );

  final edgeInset = box.width * 0.04;
  final tipGap = strokeWidth;
  final y = inkRect.center.dy;
  final hairlines = <(Offset, Offset)>[];
  if (rect.left - tipGap > edgeInset) {
    hairlines.add(
      (Offset(edgeInset, y), Offset(rect.left - tipGap, y)),
    );
  }
  if (rect.right + tipGap < box.width - edgeInset) {
    hairlines.add(
      (Offset(rect.right + tipGap, y), Offset(box.width - edgeInset, y)),
    );
  }

  return MushafCartoucheGeometry(
    cartouche: rect,
    hairlines: hairlines,
    strokeWidth: strokeWidth,
    hairlineWidth: hairlineWidth,
  );
}

/// Pointed ogee outline: pointed left/right tips, gently curved shoulders.
Path mushafCartouchePath(Rect rect) {
  final path = Path();
  final x0 = rect.left;
  final x1 = rect.right;
  final y0 = rect.top;
  final y1 = rect.bottom;
  final ym = rect.center.dy;
  final w = rect.width;
  final h = rect.height;
  final cx = rect.center.dx;

  path.moveTo(x0, ym);
  path.cubicTo(x0 + w * 0.10, y0 + h * 0.10, x0 + w * 0.28, y0, cx, y0);
  path.cubicTo(x1 - w * 0.28, y0, x1 - w * 0.10, y0 + h * 0.10, x1, ym);
  path.cubicTo(x1 - w * 0.10, y1 - h * 0.10, x1 - w * 0.28, y1, cx, y1);
  path.cubicTo(x0 + w * 0.28, y1, x0 + w * 0.10, y1 - h * 0.10, x0, ym);
  path.close();
  return path;
}

/// Paints the cartouche and its two hairlines. Strokes only, never a fill.
class MushafSurahCartouchePainter extends CustomPainter {
  const MushafSurahCartouchePainter({
    required this.geometry,
    required this.color,
  });

  final MushafCartoucheGeometry geometry;
  final Color color;

  /// Test hook: the paint used for the outline (stroke only).
  static Paint strokePaint(
    Color color,
    MushafCartoucheGeometry geometry,
  ) {
    return Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokePaint(color, geometry);
    canvas.drawPath(mushafCartouchePath(geometry.cartouche), stroke);

    final hairline = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.hairlineWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final (from, to) in geometry.hairlines) {
      canvas.drawLine(from, to, hairline);
    }
  }

  @override
  bool shouldRepaint(MushafSurahCartouchePainter oldDelegate) {
    return oldDelegate.geometry != geometry || oldDelegate.color != color;
  }
}

/// Paints the cartouche around an existing (1.0.21+69) glyph without touching
/// the glyph itself. Used by the < 600dp Mushaf path.
class MushafSurahCartoucheOverlay extends StatelessWidget {
  const MushafSurahCartoucheOverlay({
    super.key,
    required this.box,
    required this.inkRect,
    required this.color,
  });

  /// Page width x header row height.
  final Size box;

  /// Glyph ink rect in [box] coordinates.
  final Rect inkRect;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: MushafSurahCartouchePainter(
          geometry: layoutMushafCartouche(box: box, inkRect: inkRect),
          color: color,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
