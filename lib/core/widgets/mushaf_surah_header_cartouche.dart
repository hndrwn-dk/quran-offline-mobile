import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/mushaf_rosette.dart';

/// Surah header ornament: one small rosette on each side of the name, the same
/// shape as the framed sheet's corner rosettes. The glyph keeps its full ink
/// size; nothing is drawn above or below it.
@immutable
class MushafHeaderRosettesGeometry {
  const MushafHeaderRosettesGeometry({
    required this.left,
    required this.right,
    required this.size,
    required this.strokeWidth,
  });

  /// Rosette centres.
  final Offset left;
  final Offset right;
  final double size;
  final double strokeWidth;

  @override
  bool operator ==(Object other) =>
      other is MushafHeaderRosettesGeometry &&
      other.left == left &&
      other.right == right &&
      other.size == size &&
      other.strokeWidth == strokeWidth;

  @override
  int get hashCode => Object.hash(left, right, size, strokeWidth);
}

/// Gap between the name ink and a rosette, as a share of the row pitch.
const double kMushafHeaderRosetteGap = 0.5;

/// Rosette stroke colour: primary at this opacity.
const double kMushafHeaderRosetteAlpha = 0.55;

/// Rosette size in the framed page grid (reference units, scaled with the
/// frame: ~12-14dp on the Fold) and in the < 600dp flow layout (dp).
const double kMushafHeaderRosetteSizeGrid = 12.0;
const double kMushafHeaderRosetteSizeFlow = 13.0;

MushafHeaderRosettesGeometry layoutMushafHeaderRosettes({
  required Size box,
  required Rect inkRect,
  required double size,
  double? rowPitch,
}) {
  final pitch = rowPitch ?? box.height;
  final gap = pitch * kMushafHeaderRosetteGap;
  final half = size / 2;
  final y = inkRect.center.dy;
  // Keep both rosettes inside the row box, symmetric about the name.
  final reach = math.min(
    gap + half,
    math.max(0.0, math.min(inkRect.left, box.width - inkRect.right) - half),
  );
  return MushafHeaderRosettesGeometry(
    left: Offset(inkRect.left - reach, y),
    right: Offset(inkRect.right + reach, y),
    size: size,
    strokeWidth: size * 0.06,
  );
}

class MushafSurahHeaderRosettesPainter extends CustomPainter {
  const MushafSurahHeaderRosettesPainter({
    required this.geometry,
    required this.color,
  });

  final MushafHeaderRosettesGeometry geometry;

  /// Base colour (colorScheme.primary); drawn at [kMushafHeaderRosetteAlpha].
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = color.withValues(alpha: kMushafHeaderRosetteAlpha);
    for (final center in [geometry.left, geometry.right]) {
      paintMushafRosette(
        canvas,
        center,
        size: geometry.size,
        stroke: stroke,
        strokeWidth: geometry.strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(MushafSurahHeaderRosettesPainter oldDelegate) {
    return oldDelegate.geometry != geometry || oldDelegate.color != color;
  }
}

/// Header rosettes drawn over an existing glyph without touching it.
class MushafSurahHeaderRosettesOverlay extends StatelessWidget {
  const MushafSurahHeaderRosettesOverlay({
    super.key,
    required this.box,
    required this.inkRect,
    required this.color,
    required this.size,
    this.rowPitch,
  });

  final Size box;
  final Rect inkRect;
  final Color color;
  final double size;
  final double? rowPitch;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: MushafSurahHeaderRosettesPainter(
          geometry: layoutMushafHeaderRosettes(
            box: box,
            inkRect: inkRect,
            size: size,
            rowPitch: rowPitch,
          ),
          color: color,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
