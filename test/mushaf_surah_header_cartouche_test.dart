import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
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

  MushafHeaderRosettesGeometry rosettesFor(Rect ink) =>
      layoutMushafHeaderRosettes(
        box: box,
        inkRect: ink,
        size: kMushafHeaderRosetteSizeGrid,
      );

  test('all 114 surahs: rosettes half a row pitch from the ink', () {
    for (var surah = 1; surah <= 114; surah++) {
      final ink = framedInk(surah);
      final r = rosettesFor(ink);
      const half = kMushafHeaderRosetteSizeGrid / 2;
      final leftGap = ink.left - (r.left.dx + half);
      final rightGap = (r.right.dx - half) - ink.right;
      expect(leftGap, closeTo(box.height * kMushafHeaderRosetteGap, 1e-9),
          reason: 'surah $surah left');
      expect(rightGap, closeTo(leftGap, 1e-9), reason: 'surah $surah');
    }
  });

  test('rosettes are vertically centred on the name and inside the row', () {
    for (var surah = 1; surah <= 114; surah++) {
      final ink = framedInk(surah);
      final r = rosettesFor(ink);
      expect(r.left.dy, closeTo(ink.center.dy, 1e-9));
      expect(r.right.dy, closeTo(ink.center.dy, 1e-9));
      expect(r.left.dx - r.size / 2, greaterThanOrEqualTo(0));
      expect(r.right.dx + r.size / 2, lessThanOrEqualTo(box.width));
      expect(r.size / 2, lessThanOrEqualTo(box.height / 2));
    }
  });

  test('flow header rosettes stay inside a narrow phone row', () {
    const narrow = Size(358, 60);
    final ink = Rect.fromCenter(
      center: const Offset(179, 30),
      width: 330,
      height: 40,
    );
    final r = layoutMushafHeaderRosettes(
      box: narrow,
      inkRect: ink,
      size: kMushafHeaderRosetteSizeFlow,
      rowPitch: 50,
    );
    expect(r.left.dx - r.size / 2, greaterThanOrEqualTo(-1e-9));
    expect(r.right.dx + r.size / 2, lessThanOrEqualTo(narrow.width + 1e-9));
    expect(r.left.dx, lessThan(ink.left));
    expect(r.right.dx, greaterThan(ink.right));
  });

  test('painter repaints only when geometry or colour changes', () {
    final ink = framedInk(2);
    final a = MushafSurahHeaderRosettesPainter(
      geometry: rosettesFor(ink),
      color: Colors.green,
    );
    final b = MushafSurahHeaderRosettesPainter(
      geometry: rosettesFor(ink),
      color: Colors.green,
    );
    expect(a.shouldRepaint(b), isFalse);
    expect(
      a.shouldRepaint(MushafSurahHeaderRosettesPainter(
        geometry: rosettesFor(ink),
        color: Colors.red,
      )),
      isTrue,
    );
  });
}
