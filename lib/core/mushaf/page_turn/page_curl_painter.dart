import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
/// The preferred path is the cylindrical fold fragment shader
/// (`shaders/page_curl.frag`); the textured-mesh renderer below is only used
/// when the shader could not be loaded/compiled. Both paths draw the paper
/// background, the revealed pages and the gutter shade first, so the reader
/// never sees a blank hole while the leaf moves.
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
    this.tilt = 0,
    this.devicePixelRatio = 1,
    this.shader,
  });

  final PageTurnGeometry geometry;
  final Color background;
  final Color ink;
  final ui.Image? frontImage;
  final ui.Image? backImage;
  final List<PageTurnBelowPage> belowPages;
  final PageCurlSpine spineStyle;
  final double spineWidth;

  /// Finger y inside the page: -1 top .. 1 bottom.
  final double tilt;

  /// Used for antialias widths in the shader (coordinates stay logical).
  final double devicePixelRatio;

  /// Cylindrical fold shader. Null uses the CustomPainter mesh fallback.
  final ui.FragmentShader? shader;

  static String? _loggedPath;

  /// Which renderer painted last (`shader` or `painterFallback`), for tests.
  @visibleForTesting
  static String? get debugLastDrawPath => _loggedPath;

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

    // 4. The leaf itself.
    final fragmentShader = shader;
    if (fragmentShader != null && frontImage != null && backImage != null) {
      _paintShader(canvas, fragmentShader, stage);
    } else {
      _paintMesh(canvas, stage);
      _logPath('painterFallback');
    }

    canvas.restore();
  }

  void _logPath(String path) {
    if (_loggedPath == path) return;
    _loggedPath = path;
    debugPrint('[MushafCurl] draw=$path');
  }

  /// Real cylindrical fold: one shader quad over the stage.
  void _paintShader(
    Canvas canvas,
    ui.FragmentShader fragmentShader,
    Rect stage,
  ) {
    final origin = stage.topLeft;
    final leaf = geometry.leafRect.shift(-origin);
    final landed = geometry.landedRect.shift(-origin);
    final front = geometry.frontRect.shift(-origin);
    final back = geometry.backRect.shift(-origin);
    final radius = pageCurlRadius(geometry.leafRect.width, geometry.progress);

    var index = 0;
    void f(double value) => fragmentShader.setFloat(index++, value);

    // Must match the declaration order in shaders/page_curl.frag.
    f(stage.width);
    f(stage.height);
    f(leaf.left);
    f(leaf.top);
    f(leaf.width);
    f(leaf.height);
    f(landed.left);
    f(landed.top);
    f(landed.width);
    f(landed.height);
    f(front.left);
    f(front.top);
    f(front.width);
    f(front.height);
    f(back.left);
    f(back.top);
    f(back.width);
    f(back.height);
    f(geometry.progress);
    f(geometry.isForward ? 1.0 : 0.0);
    f(geometry.spread ? 1.0 : 0.0);
    f(pageCurlDiagonalOffset(
      tilt: tilt,
      pageWidth: geometry.leafRect.width,
      progress: geometry.progress,
    ));
    f(radius);
    f(devicePixelRatio);
    f(background.r);
    f(background.g);
    f(background.b);
    f(background.a);

    fragmentShader.setImageSampler(
      0,
      frontImage!,
      filterQuality: ui.FilterQuality.medium,
    );
    fragmentShader.setImageSampler(
      1,
      backImage!,
      filterQuality: ui.FilterQuality.medium,
    );

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, stage.width, stage.height),
      Paint()..shader = fragmentShader,
    );
    canvas.restore();
    _logPath('shader');
  }

  void _paintMesh(Canvas canvas, Rect stage) {
    final showFront = geometry.progress <= 0.5;
    final freeEdge = geometry.freeEdgeX;
    final edgeSign = geometry.freeEdgeSign;

    // Soft shadow the lifted leaf casts on the page below the free edge.
    _drawFreeEdgeShadow(canvas, stage, freeEdge, edgeSign);

    final rect = showFront ? geometry.frontRect : geometry.backRect;
    final image = showFront ? frontImage : backImage;
    if (rect.isEmpty) return;

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

  void _drawPageImage(Canvas canvas, ui.Image? image, Rect rect) {
    if (image == null) {
      // Never expected while a turn runs (the reader skips the curl instead),
      // but keep the page tone rather than a hole if a late frame lands here.
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
      canvas.drawRect(rect, Paint()..color = background);
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
        oldDelegate.geometry.backRect != geometry.backRect ||
        oldDelegate.tilt != tilt ||
        oldDelegate.frontImage != frontImage ||
        oldDelegate.backImage != backImage ||
        oldDelegate.background != background ||
        oldDelegate.shader != shader ||
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
