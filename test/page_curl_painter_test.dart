import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_painter.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_shader.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_snapshots.dart';

const _left = Rect.fromLTWH(0, 0, 300, 450);
const _right = Rect.fromLTWH(324, 0, 300, 450);
const _paper = Color(0xFFF7F3E8);
const _ink = Color(0xFF23211C);

Future<ui.Image> _pageImage(int seed) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 300, 450), Paint()..color = _paper);
  final paint = Paint()..color = _ink.withValues(alpha: 1 - seed * 0.1);
  for (var row = 0; row < 12; row++) {
    final y = 30.0 + row * 32;
    final inset = 24.0 + (row % 3) * 12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, y, 250 - inset * 2, 10),
        const Radius.circular(2),
      ),
      paint,
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(300, 450);
  picture.dispose();
  return image;
}

PageTurnGeometry _geometry(PageTurnDirection direction, double progress) {
  return PageTurnGeometry.spread(
    leftRect: _left,
    rightRect: _right,
    hingeGap: 24,
    direction: direction,
    progress: progress,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shader path paints the curl, fallback still works',
      (tester) async {
    final shader = await tester.runAsync(loadPageCurlShader);
    expect(shader, isNotNull,
        reason: 'the declared fragment shader must compile in tests');
    addTearDown(() => shader?.dispose());

    final front = await tester.runAsync(() => _pageImage(0));
    final back = await tester.runAsync(() => _pageImage(1));
    final revealed = await tester.runAsync(() => _pageImage(2));
    final stationary = await tester.runAsync(() => _pageImage(3));
    addTearDown(() {
      front?.dispose();
      back?.dispose();
      revealed?.dispose();
      stationary?.dispose();
    });

    for (final (direction, progress) in [
      (PageTurnDirection.forward, 0.25),
      (PageTurnDirection.forward, 0.75),
      (PageTurnDirection.backward, 0.25),
      (PageTurnDirection.backward, 0.75),
    ]) {
      final key = GlobalKey();
      final geometry = _geometry(direction, progress);
      final below = [
        PageTurnBelowPage(
          rect: direction == PageTurnDirection.forward ? _left : _right,
          image: revealed,
        ),
        PageTurnBelowPage(
          rect: direction == PageTurnDirection.forward ? _right : _left,
          image: stationary,
        ),
      ];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 624,
              height: 450,
              child: CustomPaint(
                painter: PageCurlPainter(
                  geometry: geometry,
                  background: _paper,
                  ink: _ink,
                  frontImage: front,
                  backImage: back,
                  belowPages: below,
                  tilt: direction == PageTurnDirection.forward ? 0.4 : -0.4,
                  shader: shader,
                ),
                isComplex: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      expect(boundary.debugNeedsPaint, isFalse);
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      );
      expect(image, isNotNull);
      final coverage = await tester.runAsync(() => imageInkCoverage(image!));
      image!.dispose();
      expect(coverage, greaterThan(kPageTurnMinInkCoverage),
          reason: '$direction at $progress painted blank');
      expect(PageCurlPainter.debugLastDrawPath, 'shader');
    }

    // Fallback painter path (no shader) must still draw the leaf.
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 624,
            height: 450,
            child: CustomPaint(
              painter: PageCurlPainter(
                geometry: _geometry(PageTurnDirection.forward, 0.25),
                background: _paper,
                ink: _ink,
                frontImage: front,
                backImage: back,
                belowPages: const [],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
    final coverage = await tester.runAsync(() => imageInkCoverage(image!));
    image!.dispose();
    expect(coverage, greaterThan(kPageTurnMinInkCoverage));
    expect(PageCurlPainter.debugLastDrawPath, 'painterFallback');
  });

  testWidgets('shader samples the front texture at progress 0', (tester) async {
    final shader = await tester.runAsync(loadPageCurlShader);
    expect(shader, isNotNull);
    addTearDown(() => shader?.dispose());
    final front = await tester.runAsync(() => _solidImage(const Color(0xFFFF0000)));
    final back = await tester.runAsync(() => _solidImage(const Color(0xFF00FF00)));
    addTearDown(() {
      front?.dispose();
      back?.dispose();
    });

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 624,
            height: 450,
            child: CustomPaint(
              painter: PageCurlPainter(
                geometry: _geometry(PageTurnDirection.forward, 0),
                background: _paper,
                ink: _ink,
                frontImage: front,
                backImage: back,
                belowPages: const [],
                tilt: 0.35,
                shader: shader,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final captured = await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    );
    final image = captured!;
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final bytes = data!.buffer.asUint8List();
    // Centre of the left leaf (300x450) at progress 0.
    final i = (225 * image.width + 150) * 4;
    // ignore: avoid_print
    print('image=${image.width}x${image.height} '
        'shader sample rgba=${bytes[i]},${bytes[i + 1]},${bytes[i + 2]},${bytes[i + 3]}');
    expect(bytes[i], greaterThan(180), reason: 'front red');
    expect(bytes[i + 1], lessThan(80), reason: 'front red');
    image.dispose();
  });

  testWidgets('shader works when the stage is not at the canvas origin',
      (tester) async {
    final shader = await tester.runAsync(loadPageCurlShader);
    expect(shader, isNotNull);
    addTearDown(() => shader?.dispose());
    final front = await tester.runAsync(() => _solidImage(const Color(0xFFFF0000)));
    final back = await tester.runAsync(() => _solidImage(const Color(0xFF00FF00)));
    addTearDown(() {
      front?.dispose();
      back?.dispose();
    });
    final key = GlobalKey();
    const shift = Offset(16, 16);
    final geometry = PageTurnGeometry.spread(
      leftRect: _left.shift(shift),
      rightRect: _right.shift(shift),
      hingeGap: 24,
      direction: PageTurnDirection.forward,
      progress: 0.25,
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 933,
            height: 704,
            child: CustomPaint(
              painter: PageCurlPainter(
                geometry: geometry,
                background: _paper,
                ink: _ink,
                frontImage: front,
                backImage: back,
                belowPages: const [],
                tilt: 0.35,
                shader: shader,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final captured = await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    );
    final image = captured!;
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final bytes = data!.buffer.asUint8List();
    // Front leaf still covers the spine side at p=0.25.
    const x = 16 + 250;
    const y = 16 + 225;
    final i = (y * image.width + x) * 4;
    // ignore: avoid_print
    print('shifted sample rgba=${bytes[i]},${bytes[i + 1]},${bytes[i + 2]}');
    expect(bytes[i], greaterThan(180));
    expect(bytes[i + 1], lessThan(80));
    image.dispose();
  });
}

Future<ui.Image> _solidImage(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 300, 450), Paint()..color = color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(300, 450);
  picture.dispose();
  return image;
}
