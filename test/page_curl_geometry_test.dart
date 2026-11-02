import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_geometry.dart';

/// Fold 8 inner spread, roughly: two 400x600 sheets with an 8px gutter.
const _left = Rect.fromLTWH(58, 40, 400, 600);
const _right = Rect.fromLTWH(466, 40, 400, 600);

/// Where the back layer of the fold puts leaf point [p] (mirrors the shader).
Offset _backOf(PageCurlFrame f, Offset p) {
  final d = f.distance(p);
  return p + f.normal * (math.pi * f.radius - 2 * d);
}

void main() {
  group('PageCurlLeaf', () {
    test('spread forward lifts the left sheet around the gutter middle', () {
      final leaf = PageCurlLeaf.spread(left: _left, right: _right, forward: true);
      expect(leaf.rect, _left);
      expect(leaf.side, 1);
      expect(leaf.hingeX, 462);
      expect(leaf.innerOffset, 4);
      expect(leaf.freeEdge, 404);
      // The outer left edge is the free edge.
      expect(leaf.toLeaf(Offset(_left.left, 100)).dx, closeTo(404, 1e-9));
    });

    test('spread backward lifts the right sheet (mirror)', () {
      final leaf =
          PageCurlLeaf.spread(left: _left, right: _right, forward: false);
      expect(leaf.rect, _right);
      expect(leaf.side, -1);
      expect(leaf.toLeaf(Offset(_right.right, 100)).dx, closeTo(404, 1e-9));
    });

    test('single page hinges on its right edge', () {
      final leaf = PageCurlLeaf.single(_left);
      expect(leaf.hingeX, _left.right);
      expect(leaf.innerOffset, 0);
      expect(leaf.toLeaf(Offset(_left.left, 0)).dx, closeTo(400, 1e-9));
    });

    test('toStage inverts toLeaf', () {
      for (final forward in [true, false]) {
        final leaf =
            PageCurlLeaf.spread(left: _left, right: _right, forward: forward);
        const p = Offset(123.5, 456.25);
        final back = leaf.toStage(leaf.toLeaf(p));
        expect(back.dx, closeTo(p.dx, 1e-9));
        expect(back.dy, closeTo(p.dy, 1e-9));
      }
    });
  });

  group('computePageCurl', () {
    final leaf = PageCurlLeaf.spread(left: _left, right: _right, forward: true);
    final edge = leaf.freeEdge;
    final h = leaf.height;

    test('untouched leaf is flat', () {
      final grab = Offset(edge, h * 0.5);
      final f = computePageCurl(leaf: leaf, grab: grab, finger: grab);
      expect(f.radius, 0);
      expect(f.progress, 0);
      expect(f.strength, 0);
      // Every point of the leaf is on the flat side of the fold.
      expect(f.distance(Offset(edge, 0)), lessThanOrEqualTo(0));
      expect(f.distance(Offset(edge, h)), lessThanOrEqualTo(0));
    });

    test('landed leaf lies mirrored on the other page, no curl', () {
      final grab = Offset(edge, h * 0.9);
      final f = computePageCurl(
        leaf: leaf,
        grab: grab,
        finger: Offset(-edge, h * 0.9),
      );
      expect(f.progress, 1);
      expect(f.radius, 0);
      expect(f.strength, 0);
      expect(f.origin.dx, closeTo(0, 1e-9));
      expect(f.normal.dx, closeTo(1, 1e-9));
      // A leaf point lands at its mirror image across the spine.
      final landed = _backOf(f, const Offset(-150, 300));
      expect(landed.dx, closeTo(150, 1e-9));
      expect(landed.dy, closeTo(300, 1e-9));
    });

    test('mid-edge horizontal drag gives a vertical fold', () {
      final f = computePageCurl(
        leaf: leaf,
        grab: Offset(edge, h / 2),
        finger: Offset(edge * 0.4, h / 2),
      );
      expect(f.normal.dx, closeTo(1, 1e-9));
      expect(f.normal.dy, closeTo(0, 1e-9));
      expect(f.radius, greaterThan(0));
    });

    test('lower-corner drag up and across lifts the lower corner first', () {
      final f = computePageCurl(
        leaf: leaf,
        grab: Offset(edge, h),
        finger: Offset(edge * 0.6, h * 0.75),
      );
      expect(f.normal.dy, greaterThan(0.1));
      // The lower outer corner is past the fold; the upper one is not.
      expect(f.distance(Offset(edge, h)), greaterThan(0));
      expect(f.distance(Offset(edge, 0)), lessThan(f.distance(Offset(edge, h))));
      expect(f.distance(Offset(edge, 0)), lessThan(0));
    });

    test('the grabbed point lands under the finger', () {
      final grab = Offset(edge, h * 0.8);
      const finger = Offset(250, 420);
      final f = computePageCurl(leaf: leaf, grab: grab, finger: finger);
      final landed = _backOf(f, finger);
      expect(landed.dx, closeTo(grab.dx, 1e-6));
      expect(landed.dy, closeTo(grab.dy, 1e-6));
    });

    test('the spine never lifts, whatever the finger does', () {
      final random = math.Random(7);
      for (var i = 0; i < 2000; i++) {
        final grab = Offset(edge, random.nextDouble() * h);
        final finger = Offset(
          (random.nextDouble() * 2 - 1) * edge * 1.2,
          (random.nextDouble() * 1.6 - 0.3) * h,
        );
        final f = computePageCurl(leaf: leaf, grab: grab, finger: finger);
        expect(f.normal.distance, closeTo(1, 1e-9));
        expect(f.normal.dx, greaterThanOrEqualTo(0.5 - 1e-9));
        expect(f.distance(const Offset(0, 0)), lessThanOrEqualTo(1e-6));
        expect(f.distance(Offset(0, h)), lessThanOrEqualTo(1e-6));
        expect(f.radius, lessThanOrEqualTo(0.1 * leaf.width + 1e-9));
        expect(f.progress, inInclusiveRange(0, 1));
      }
    });

    test('the leaf straightens as it nears the spine', () {
      // A finger held well above the grab point would otherwise keep the
      // fold steep and land the leaf rotated.
      var lastTilt = double.infinity;
      for (final t in [0.6, 0.75, 0.9, 0.98]) {
        final f = computePageCurl(
          leaf: leaf,
          grab: Offset(edge, h * 0.9),
          finger: Offset(edge - 2 * edge * t, h * 0.6),
        );
        final tilt = (f.normal.dy / f.normal.dx).abs();
        expect(tilt, lessThanOrEqualTo(lastTilt + 1e-9));
        lastTilt = tilt;
      }
      expect(lastTilt, lessThan(0.08));
    });

    test('progress grows as the finger crosses towards the spine', () {
      var last = -1.0;
      for (var u = edge; u >= -edge; u -= 20) {
        final f = computePageCurl(
          leaf: leaf,
          grab: Offset(edge, h / 2),
          finger: Offset(u, h / 2),
        );
        expect(f.progress, greaterThanOrEqualTo(last));
        last = f.progress;
      }
      expect(last, closeTo(1, 0.03));
    });

    test('radius follows the factor (8-12% of the page width)', () {
      for (final factor in [0.08, 0.12]) {
        final f = computePageCurl(
          leaf: leaf,
          grab: Offset(edge, h / 2),
          finger: Offset(0, h / 2),
          radiusFactor: factor,
        );
        expect(f.radius, closeTo(factor * leaf.width, 1e-9));
      }
    });
  });

  group('auto turn path', () {
    final leaf = PageCurlLeaf.single(_left);

    test('starts at the grab point and ends at the landing spot', () {
      final grab = pageCurlAutoGrab(leaf);
      final start = pageCurlAutoFinger(leaf, 0);
      final end = pageCurlAutoFinger(leaf, 1);
      expect(start.dx, closeTo(grab.dx, 1e-9));
      expect(start.dy, closeTo(grab.dy, 1e-9));
      expect(end.dx, closeTo(-leaf.freeEdge, 1e-9));
      expect(end.dy, closeTo(grab.dy, 1e-6));
      expect(
        computePageCurl(leaf: leaf, grab: grab, finger: end).progress,
        1,
      );
    });

    test('rises mid-turn so the lower corner leads', () {
      final mid = pageCurlAutoFinger(leaf, 0.5);
      expect(mid.dy, lessThan(pageCurlAutoGrab(leaf).dy));
      final f = computePageCurl(
        leaf: leaf,
        grab: pageCurlAutoGrab(leaf),
        finger: mid,
      );
      expect(f.normal.dy, greaterThan(0));
    });
  });
}
