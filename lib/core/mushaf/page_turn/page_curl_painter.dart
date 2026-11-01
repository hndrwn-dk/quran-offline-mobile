import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';

/// One page drawn under the lifted leaf.
class PageTurnBelowPage {
  const PageTurnBelowPage({required this.rect, required this.image});

  final Rect rect;
  final ui.Image? image;
}

/// Paints the curled leaf over the already-rasterized pages.
///
/// Only used while a turn is active: idle pages stay live widgets, so the painter
/// never touches static rendering. The leaf is a textured mesh (the page
/// snapshot) whose free edge bows outward; shading and shadows are painted on
/// top of it, and the page below gets a soft shadow under the free edge.
///
/// A fragment shader would allow a real cylindrical curl; for this first pass the
/// mesh + gradients are enough and keep the turn cheap and testable.
class PageCurlPainter extends CustomPainter {
  PageCurlPainter({
    required this.geometry,
    required this.background,
    required this.ink,
    required this.frontImage,
    required this.backImage,
    required this.belowPages,
    this.spineStyle = PageCurlSpine.soft,
    this.spineWidth = 12,
  });

  final PageTurnGeometry geometry;
  final Color background;
  final Color ink;
  final ui.Image? frontImage;
  final ui.Image? backImage;
  final List<PageTurnBelowPage> belowPages;
  final PageCurlSpine spineStyle;
  final double spineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stage = geometry.stageRect;
    if (stage.isEmpty) return;

    canvas.save();
    canvas.clipRect(stage);

    // 1. Paper background (also covers the gutter between the two pages).
    canvas.drawRect(stage, Paint()..color = background);

    // 2. Pages underneath: the revealed neighbour plus the untouched page.
    for (final page in belowPages) {
      _drawPageImage(canvas, page.image, page.rect);
    }

    // 3. Printed-book gutter shade.
    if (spineStyle == PageCurlSpine.soft && geometry.hingeGap > 0) {
      _drawSpineShade(canvas, stage);
    }

    final showFront = geometry.progress <= 0.5;
    final freeEdge = geometry.freeEdgeX;
    final edgeSign = geometry.freeEdgeSign;

    // 4. Soft shadow the lifted leaf casts on the page below the free edge.
    _drawFreeEdgeShadow(canvas, stage, freeEdge, edgeSign);

    // 5. The curled leaf itself (front before half a turn, back after).
    final rect = showFront ? geometry.frontRect : geometry.backRect;
    final image = showFront ? frontImage : backImage;
    if (!rect.isEmpty) {
      // A spread's hinge is the gutter centre; the front page content runs from
      // the outer edge inward, the back page content from the hinge outward.
      final innerIsLeft = geometry.pivotX <= rect.center.dx;
      final texAtInner = showFront
          ? (geometry.isForward ? 1.0 : 0.0)
          : (geometry.isForward ? 0.0 : 1.0);
      final texSign = showFront
          ? (geometry.isForward ? -1.0 : 1.0)
          : (geometry.isForward ? 1.0 : -1.0);
      final leafPath = _leafPath(
        rect: rect,
        innerIsLeft: innerIsLeft,
        bow: geometry.curlDepth,
      );
      _drawLeafImage(
        canvas,
        rect: rect,
        image: image,
        innerIsLeft: innerIsLeft,
        bow: geometry.curlDepth,
        texAtInner: texAtInner,
        texSign: texSign,
      );
      canvas.save();
      canvas.clipPath(leafPath);
      _drawLeafShading(canvas, rect, innerIsLeft);
      canvas.restore();
      _drawFreeEdgeLine(canvas, leafPath);
    }

    canvas.restore();
  }

  void _drawPageImage(Canvas canvas, ui.Image? image, Rect rect) {
    if (image == null) {
      // Snapshot not ready yet (cold start): keep the page tone, never a hole.
      canvas.drawRect(rect, Paint()..color = background);
      return;
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _drawSpineShade(Canvas canvas, Rect stage) {
    final center = geometry.pivotX;
    final half = math.max(spineWidth, 2.0) / 2;
    final rect =
        Rect.fromLTRB(center - half, stage.top, center + half, stage.bottom);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left, 0),
        Offset(rect.right, 0),
        [
          ink.withValues(alpha: 0),
          ink.withValues(alpha: 0.04),
          ink.withValues(alpha: 0),
        ],
        const [0, 0.5, 1],
      );
    canvas.drawRect(rect, paint);
  }

  void _drawFreeEdgeShadow(
    Canvas canvas,
    Rect stage,
    double freeEdge,
    double edgeSign,
  ) {
    final strength = math.sin(math.pi * geometry.progress);
    if (strength <= 0.01) return;
    final width = (geometry.leafRect.width * 0.10).clamp(10.0, 60.0);
    final outer = Rect.fromLTRB(
      math.min(freeEdge, freeEdge + edgeSign * width),
      stage.top,
      math.max(freeEdge, freeEdge + edgeSign * width),
      stage.bottom,
    );
    if (outer.isEmpty) return;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(freeEdge, 0),
        Offset(freeEdge + edgeSign * width, 0),
        [
          Colors.black.withValues(alpha: 0.20 * strength),
          Colors.black.withValues(alpha: 0),
        ],
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.35);
    canvas.drawRect(outer, paint);
  }

  /// Grid of quads between the hinge and the bowed free edge.
  ///
  /// [innerIsLeft] says which side of [rect] touches the hinge; [texAtInner] and
  /// [texSign] map the hinge→free-edge axis onto the page image, so the leaf back
  /// shows the real page content unmirrored.
  void _drawLeafImage(
    Canvas canvas, {
    required Rect rect,
    required ui.Image? image,
    required bool innerIsLeft,
    required double bow,
    required double texAtInner,
    required double texSign,
  }) {
    if (image == null) {
      final fallback = Paint()..color = background;
      canvas.drawRect(rect, fallback);
      return;
    }
    const columns = kPageTurnMeshColumns;
    const rows = kPageTurnMeshRows;
    final positions = Float32List((columns + 1) * (rows + 1) * 2);
    final texCoords = Float32List((columns + 1) * (rows + 1) * 2);
    final indices = <int>[];
    final sign = innerIsLeft ? 1.0 : -1.0;
    final innerX = innerIsLeft ? rect.left : rect.right;
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    var v = 0;
    for (var row = 0; row <= rows; row++) {
      final fv = row / rows;
      final curve = math.sin(math.pi * fv);
      for (var col = 0; col <= columns; col++) {
        final fu = col / columns;
        final x = innerX + sign * (fu * rect.width + bow * fu * fu * curve);
        final y = rect.top + fv * rect.height;
        positions[v * 2] = x;
        positions[v * 2 + 1] = y;
        final texU = (texAtInner + texSign * fu).clamp(0.0, 1.0);
        texCoords[v * 2] = texU * imageWidth;
        texCoords[v * 2 + 1] = fv * imageHeight;
        v++;
      }
    }
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final tl = row * (columns + 1) + col;
        final tr = tl + 1;
        final bl = tl + (columns + 1);
        final br = bl + 1;
        indices.addAll([tl, bl, tr, tr, bl, br]);
      }
    }

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texCoords,
      indices: Uint16List.fromList(indices),
    );
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        _identityMatrix,
        filterQuality: FilterQuality.medium,
      );
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
  }

  Path _leafPath({
    required Rect rect,
    required bool innerIsLeft,
    required double bow,
  }) {
    const steps = 16;
    final sign = innerIsLeft ? 1.0 : -1.0;
    final innerX = innerIsLeft ? rect.left : rect.right;
    final path = Path()..moveTo(innerX, rect.top);
    // Outer (free) edge, top to bottom.
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = innerX + sign * (rect.width + bow * math.sin(math.pi * t));
      path.lineTo(x, rect.top + t * rect.height);
    }
    // Inner (hinge) edge, bottom to top.
    path.lineTo(innerX, rect.bottom);
    path.close();
    return path;
  }

  void _drawLeafShading(Canvas canvas, Rect rect, bool innerIsLeft) {
    final strength = 0.35 + 0.65 * math.sin(math.pi * geometry.progress);
    final innerX = innerIsLeft ? rect.left : rect.right;
    final outerX = innerIsLeft ? rect.right : rect.left;
    final shadowWidth = (rect.width * 0.45).clamp(8.0, 90.0);
    final foldEnd = innerX + (innerIsLeft ? shadowWidth : -shadowWidth);
    // Hinge darkening (the leaf bends away from the gutter).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(innerX, 0),
          Offset(foldEnd, 0),
          [
            Colors.black.withValues(alpha: 0.06 + 0.16 * strength),
            Colors.black.withValues(alpha: 0),
          ],
        ),
    );
    // Light catching the lifted outer edge.
    final highlightWidth = (rect.width * 0.30).clamp(6.0, 70.0);
    final highlightStart =
        outerX + (innerIsLeft ? -highlightWidth : highlightWidth);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(outerX, 0),
          Offset(highlightStart, 0),
          [
            Colors.white.withValues(alpha: 0.05 + 0.07 * strength),
            Colors.white.withValues(alpha: 0),
          ],
        ),
    );
  }

  void _drawFreeEdgeLine(Canvas canvas, Path leafPath) {
    final strength = math.sin(math.pi * geometry.progress);
    if (strength <= 0.02) return;
    canvas.drawPath(
      leafPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ink.withValues(alpha: 0.08 + 0.10 * strength),
    );
  }

  @override
  bool shouldRepaint(PageCurlPainter oldDelegate) {
    return oldDelegate.geometry.progress != geometry.progress ||
        oldDelegate.geometry.frontRect != geometry.frontRect ||
        oldDelegate.frontImage != frontImage ||
        oldDelegate.backImage != backImage ||
        oldDelegate.background != background ||
        oldDelegate.belowPages != belowPages;
  }
}

/// How the gutter between two pages of a spread is painted under the leaf.
enum PageCurlSpine { none, soft }

/// Column-major identity matrix for [ui.ImageShader].
final Float64List _identityMatrix = Float64List.fromList(<double>[
  1, 0, 0, 0, //
  0, 1, 0, 0, //
  0, 0, 1, 0, //
  0, 0, 0, 1, //
]);
