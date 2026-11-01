import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/surah_name_glyph_metrics.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:quran_offline/core/widgets/mushaf_surah_header_cartouche.dart';

void main() {
  const box = Size(kMushafPageLayoutWidth, kMushafPageRowHeight);

  Rect framedInk(int surah) {
    final layout = layoutSurahNameInk(
      surahId: surah,
      targetInkHeight: kMushafPageRowHeight * kSurahNameInkHeightFactor,
      maxInkWidth: kMushafPageLayoutWidth * kSurahNameMaxInkWidthFactor,
    );
    return Rect.fromCenter(
      center: Offset(box.width / 2, box.height / 2),
      width: layout.inkWidth,
      height: layout.inkHeight,
    );
  }

  test('all 114 surahs keep the caps clear of the ink', () {
    for (var surah = 1; surah <= 114; surah++) {
      final ink = framedInk(surah);
      final caps = layoutMushafEndCaps(box: box, inkRect: ink);
      final minGap = box.height * 0.5;

      expect(
        caps.leftCap.right,
        lessThanOrEqualTo(ink.left - minGap + 0.01),
        reason: 'surah $surah left cap intersects ink',
      );
      expect(
        caps.rightCap.left,
        greaterThanOrEqualTo(ink.right + minGap - 0.01),
        reason: 'surah $surah right cap intersects ink',
      );
      expect(
        caps.leftCap.right,
        lessThan(ink.left),
        reason: 'surah $surah left cap overlaps ink',
      );
      expect(
        caps.rightCap.left,
        greaterThan(ink.right),
        reason: 'surah $surah right cap overlaps ink',
      );
    }
  });

  test('all 114 surahs keep the caps inside the row and page width', () {
    for (var surah = 1; surah <= 114; surah++) {
      final ink = framedInk(surah);
      final caps = layoutMushafEndCaps(box: box, inkRect: ink);
      for (final cap in [caps.leftCap, caps.rightCap]) {
        expect(cap.top, greaterThanOrEqualTo(0), reason: 'surah $surah');
        expect(cap.bottom, lessThanOrEqualTo(box.height), reason: 'surah $surah');
        expect(cap.left, greaterThanOrEqualTo(0), reason: 'surah $surah');
        expect(cap.right, lessThanOrEqualTo(box.width), reason: 'surah $surah');
      }
    }
  });

  test('cap height follows the row pitch and is vertically centred', () {
    final ink = framedInk(2);
    final caps = layoutMushafEndCaps(box: box, inkRect: ink);
    expect(caps.leftCap.height, greaterThanOrEqualTo(box.height * kMushafEndCapHeight - 0.01));
    expect(caps.leftCap.height, lessThanOrEqualTo(box.height));
    expect(caps.leftCap.center.dy, closeTo(ink.center.dy, 0.01));
    expect(caps.rightCap.center.dy, closeTo(ink.center.dy, 0.01));
  });

  test('caps use the ink colour with the two stroke weights', () {
    final geo = layoutMushafEndCaps(box: box, inkRect: framedInk(1));
    final outer = MushafSurahEndCapsPainter.outerPaint(Colors.black, geo);
    expect(outer.style, PaintingStyle.stroke);
    expect(outer.color.a, closeTo(0.6, 0.02));
    expect(geo.strokeWidth, closeTo(kMushafEndCapStroke, 1e-9));
    expect(geo.innerStrokeWidth, closeTo(kMushafEndCapInnerStroke, 1e-9));
  });

  test('the cap path opens toward the name', () {
    final rect = Rect.fromLTWH(10, 5, 10, 30);
    final left = mushafEndCapPath(rect, openingRight: true).getBounds();
    final right = mushafEndCapPath(rect, openingRight: false).getBounds();
    expect(left.width, closeTo(rect.width, 0.5));
    expect(right.width, closeTo(rect.width, 0.5));
    // Both are arcs: their bounds are the cap rect (tips end at the edges).
    expect(left.top, closeTo(rect.top - 0.8, 0.8));
    expect(right.bottom, closeTo(rect.bottom + 0.8, 0.8));
  });

  test('shouldRepaint only on geometry/colour change', () {
    final ink = framedInk(1);
    final a = MushafSurahEndCapsPainter(
      geometry: layoutMushafEndCaps(box: box, inkRect: ink),
      color: Colors.black,
    );
    final b = MushafSurahEndCapsPainter(
      geometry: layoutMushafEndCaps(box: box, inkRect: ink),
      color: Colors.black,
    );
    expect(b.shouldRepaint(a), isFalse);
    final c = MushafSurahEndCapsPainter(
      geometry: layoutMushafEndCaps(box: box, inkRect: ink),
      color: Colors.white,
    );
    expect(c.shouldRepaint(a), isTrue);
  });

  test('metrics table is complete for the cap layout', () {
    expect(kSurahNameGlyphInk.length, 114);
    expect(kSurahNameGlyphUnitsPerEm, 1024);
  });
}

