import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_geometry.dart';

/// Asset key of the cylindrical fold shader (declared in `pubspec.yaml`).
const String kPageCurlShaderAsset = 'shaders/page_curl.frag';

Future<ui.FragmentProgram>? _program;

/// Loads the fold shader once per process.
///
/// A failure is not cached as success: the caller logs it and turns the page
/// with the slide instead.
Future<ui.FragmentProgram> loadPageCurlProgram() {
  return _program ??= ui.FragmentProgram.fromAsset(kPageCurlShaderAsset)
      .catchError((Object error) {
    _program = null;
    throw error;
  });
}

/// Writes every uniform and both samplers of [shader] for one frame.
///
/// The float order matches the declaration order in `page_curl.frag`.
void setPageCurlUniforms(
  ui.FragmentShader shader, {
  required Size size,
  required PageCurlLeaf leaf,
  required PageCurlFrame frame,
  required bool dark,
  required ui.Image front,
  required ui.Image back,
}) {
  var i = 0;
  void f(double value) => shader.setFloat(i++, value);
  f(size.width);
  f(size.height);
  f(leaf.rect.left);
  f(leaf.rect.top);
  f(leaf.rect.width);
  f(leaf.rect.height);
  f(leaf.hingeX);
  f(leaf.side);
  f(frame.origin.dx);
  f(frame.origin.dy);
  f(frame.normal.dx);
  f(frame.normal.dy);
  f(frame.radius);
  f(frame.strength);
  f(dark ? 1 : 0);
  shader.setImageSampler(0, front, filterQuality: ui.FilterQuality.low);
  shader.setImageSampler(1, back, filterQuality: ui.FilterQuality.low);
}

/// Paints the moving leaf over the stage; transparent everywhere else.
class PageCurlPainter extends CustomPainter {
  PageCurlPainter({
    required this.shader,
    required this.leaf,
    required this.frame,
    required this.front,
    required this.back,
    required this.dark,
  });

  final ui.FragmentShader shader;
  final PageCurlLeaf leaf;
  final PageCurlFrame frame;
  final ui.Image front;
  final ui.Image back;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    setPageCurlUniforms(
      shader,
      size: size,
      leaf: leaf,
      frame: frame,
      dark: dark,
      front: front,
      back: back,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(PageCurlPainter oldDelegate) => true;
}

/// Debug log for the page-turn path.
void logPageCurl(String message) => debugPrint('[MushafCurl] $message');
