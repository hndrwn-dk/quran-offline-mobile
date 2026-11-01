import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/mushaf_sheet_layout.dart';

/// Colors of the framed Mushaf "desk", all derived from [ColorScheme] tokens so
/// light, dark and sepia schemes each get their own paper.
class MushafPaperPalette {
  const MushafPaperPalette({
    required this.desk,
    required this.sheet,
    required this.edge,
    required this.spine,
    required this.shadow,
    required this.frameOuter,
    required this.frameInner,
    required this.rosette,
    required this.number,
  });

  factory MushafPaperPalette.of(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final ink = scheme.onSurface;
    return MushafPaperPalette(
      // Light: cream sheet on a slightly darker cream desk. Dark: the sheet is
      // a few percent lighter than the green-black desk.
      desk: isDark ? scheme.surface : scheme.surfaceContainerHigh,
      sheet: scheme.surfaceContainerLow,
      edge: ink.withValues(alpha: isDark ? 0.16 : 0.12),
      spine: ink.withValues(alpha: isDark ? 0.10 : 0.06),
      shadow:
          isDark ? Colors.transparent : scheme.shadow.withValues(alpha: 0.07),
      frameOuter: scheme.primary.withValues(alpha: 0.22),
      frameInner: scheme.primary.withValues(alpha: 0.14),
      rosette: scheme.primary.withValues(alpha: 0.45),
      number: scheme.primary.withValues(alpha: 0.80),
    );
  }

  final Color desk;
  final Color sheet;
  final Color edge;
  final Color spine;
  final Color shadow;
  final Color frameOuter;
  final Color frameInner;
  final Color rosette;
  final Color number;

  @override
  bool operator ==(Object other) =>
      other is MushafPaperPalette &&
      other.desk == desk &&
      other.sheet == sheet &&
      other.edge == edge &&
      other.spine == spine &&
      other.shadow == shadow &&
      other.frameOuter == frameOuter &&
      other.frameInner == frameInner &&
      other.rosette == rosette &&
      other.number == number;

  @override
  int get hashCode => Object.hash(
        desk,
        sheet,
        edge,
        spine,
        shadow,
        frameOuter,
        frameInner,
        rosette,
        number,
      );
}

/// Where a sheet sits in the book (decides spine and stack sides).
class MushafSheetSide {
  const MushafSheetSide({
    required this.rect,
    required this.onRight,
    required this.stackEdges,
  });

  final Rect rect;

  /// Right-hand (odd) page: spine on its left, stack on its right.
  final bool onRight;
  final int stackEdges;
}

/// Paper under the text: soft shadow, page-stack edges, sheet, spine shade.
class MushafPaperPainter extends CustomPainter {
  const MushafPaperPainter({
    required this.sheets,
    required this.palette,
    required this.showStack,
  });

  final List<MushafSheetSide> sheets;
  final MushafPaperPalette palette;
  final bool showStack;

  static const double _spineShadeWidth = 18;
  static const double _edgeInsetStep = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    final sheetPaint = Paint()..color = palette.sheet;

    if (palette.shadow.a > 0) {
      final shadowPaint = Paint()
        ..color = palette.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      for (final sheet in sheets) {
        canvas.drawRect(sheet.rect.shift(const Offset(0, 1.5)), shadowPaint);
      }
    }

    if (showStack) {
      final edgePaint = Paint()
        ..color = palette.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      for (final sheet in sheets) {
        final outward = sheet.onRight ? 1.0 : -1.0;
        // Deepest edge first so each one peeks out from behind the next.
        for (var i = sheet.stackEdges; i >= 1; i--) {
          final rect = Rect.fromLTRB(
            sheet.rect.left,
            sheet.rect.top + i * _edgeInsetStep,
            sheet.rect.right,
            sheet.rect.bottom - i * _edgeInsetStep,
          ).shift(Offset(outward * i * kMushafStackEdgeStep, 0));
          canvas.drawRect(rect, sheetPaint);
          final x = sheet.onRight ? rect.right - 0.25 : rect.left + 0.25;
          canvas.drawLine(
            Offset(x, rect.top),
            Offset(x, rect.bottom),
            edgePaint,
          );
        }
      }
    }

    for (final sheet in sheets) {
      canvas.drawRect(sheet.rect, sheetPaint);
      // Soft shade where the paper curves into the spine (inner edge only).
      final inner = sheet.onRight
          ? Rect.fromLTWH(
              sheet.rect.left,
              sheet.rect.top,
              _spineShadeWidth,
              sheet.rect.height,
            )
          : Rect.fromLTWH(
              sheet.rect.right - _spineShadeWidth,
              sheet.rect.top,
              _spineShadeWidth,
              sheet.rect.height,
            );
      final shade = palette.spine;
      canvas.drawRect(
        inner,
        Paint()
          ..shader = LinearGradient(
            begin: sheet.onRight ? Alignment.centerLeft : Alignment.centerRight,
            end: sheet.onRight ? Alignment.centerRight : Alignment.centerLeft,
            colors: [shade, shade.withValues(alpha: 0)],
          ).createShader(inner),
      );
    }
  }

  @override
  bool shouldRepaint(MushafPaperPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.showStack != showStack ||
      !_sameSheets(oldDelegate.sheets, sheets);
}

bool _sameSheets(List<MushafSheetSide> a, List<MushafSheetSide> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].rect != b[i].rect ||
        a[i].onRight != b[i].onRight ||
        a[i].stackEdges != b[i].stackEdges) {
      return false;
    }
  }
  return true;
}

/// Thin double frame and corner rosettes drawn inside each sheet's margin.
class MushafFramePainter extends CustomPainter {
  const MushafFramePainter({
    required this.sheets,
    required this.decor,
    required this.palette,
  });

  final List<Rect> sheets;
  final MushafSheetDecor decor;
  final MushafPaperPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (!decor.hasOuterFrame) return;
    final outer = Paint()
      ..color = palette.frameOuter
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMushafFrameOuterStroke;
    final inner = Paint()
      ..color = palette.frameInner
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMushafFrameInnerStroke;

    for (final sheet in sheets) {
      canvas.drawRect(sheet.deflate(kMushafFrameEdgeInset), outer);
      if (decor.hasInnerFrame) {
        canvas.drawRect(
          sheet.deflate(kMushafFrameEdgeInset + kMushafFrameLineGap),
          inner,
        );
      }
      if (decor.hasRosettes) {
        const half = kMushafRosetteSize / 2;
        for (final corner in [
          sheet.topLeft + const Offset(half, half),
          sheet.topRight + const Offset(-half, half),
          sheet.bottomLeft + const Offset(half, -half),
          sheet.bottomRight + const Offset(-half, -half),
        ]) {
          _paintRosette(canvas, corner);
        }
      }
    }
  }

  /// Two overlapping squares (0° and 45°) around a small circle.
  void _paintRosette(Canvas canvas, Offset center) {
    const outerExtent = kMushafRosetteSize / 2;
    // The 45° square spans the full rosette; the 0° square has the same side.
    const side = kMushafRosetteSize / math.sqrt2;
    final square = Rect.fromCenter(center: center, width: side, height: side);
    final diamond = Path()
      ..moveTo(center.dx, center.dy - outerExtent)
      ..lineTo(center.dx + outerExtent, center.dy)
      ..lineTo(center.dx, center.dy + outerExtent)
      ..lineTo(center.dx - outerExtent, center.dy)
      ..close();

    // Paper fill hides the frame lines that run under the rosette.
    final fill = Paint()..color = palette.sheet;
    canvas
      ..drawRect(square, fill)
      ..drawPath(diamond, fill);

    final stroke = Paint()
      ..color = palette.rosette
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas
      ..drawRect(square, stroke)
      ..drawPath(diamond, stroke)
      ..drawCircle(center, kMushafRosetteSize * 0.17, stroke);
  }

  @override
  bool shouldRepaint(MushafFramePainter oldDelegate) =>
      oldDelegate.decor != decor ||
      oldDelegate.palette != palette ||
      oldDelegate.sheets.length != sheets.length ||
      !Iterable<int>.generate(sheets.length)
          .every((i) => oldDelegate.sheets[i] == sheets[i]);
}

const _arabicIndicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// `603` -> `٦٠٣`.
String toArabicIndicDigits(int value) => value
    .toString()
    .split('')
    .map((d) => _arabicIndicDigits[int.parse(d)])
    .join();

/// Page number printed in a sheet's bottom margin: "· ٦٠٣ ·".
class MushafSheetPageNumber extends StatelessWidget {
  const MushafSheetPageNumber({
    super.key,
    required this.pageNo,
    required this.color,
    this.semanticsLabel,
  });

  final int pageNo;
  final Color color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? '$pageNo',
      excludeSemantics: true,
      child: Text(
        '·  ${toArabicIndicDigits(pageNo)}  ·',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        // The margin band is exactly one 11dp line; never let it grow.
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1),
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: kMushafSheetNumberFontSize,
          height: 1.0,
          color: color,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );
  }
}
