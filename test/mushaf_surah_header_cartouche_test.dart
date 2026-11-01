import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:quran_offline/core/widgets/mushaf_surah_header_cartouche.dart';

void main() {
  final box = Size(kMushafPageLayoutWidth, kMushafPageRowHeight);

  group('cartouche geometry', () {
    test('wraps the ink with side padding and stays in the box', () {
      final ink = Rect.fromCenter(
        center: Offset(box.width / 2, box.height / 2),
        width: 100,
        height: 34,
      );
      final geo = layoutMushafCartouche(box: box, inkRect: ink);

      expect(geo.cartouche.width, greaterThan(ink.width));
      expect(geo.cartouche.left, greaterThan(0));
      expect(geo.cartouche.right, lessThan(box.width));
      expect(geo.cartouche.top, greaterThanOrEqualTo(0));
      expect(geo.cartouche.bottom, lessThanOrEqualTo(box.height));
      expect(geo.cartouche.center.dx, closeTo(ink.center.dx, 0.01));
      expect(geo.cartouche.center.dy, closeTo(ink.center.dy, 0.01));
    });

    test('short names get the minimum width', () {
      final ink = Rect.fromCenter(
        center: Offset(box.width / 2, box.height / 2),
        width: 40,
        height: 30,
      );
      final geo = layoutMushafCartouche(box: box, inkRect: ink);
      expect(
        geo.cartouche.width,
        greaterThanOrEqualTo(box.height * kMushafCartoucheMinWidth - 0.01),
      );
    });

    test('two hairlines end 4% before the page edges', () {
      final ink = Rect.fromCenter(
        center: Offset(box.width / 2, box.height / 2),
        width: 120,
        height: 34,
      );
      final geo = layoutMushafCartouche(box: box, inkRect: ink);
      expect(geo.hairlines.length, 2);

      final inset = box.width * 0.04;
      final left = geo.hairlines.first;
      final right = geo.hairlines.last;
      expect(left.$1.dx, closeTo(inset, 0.01));
      expect(left.$2.dx, lessThan(geo.cartouche.left));
      expect(right.$2.dx, closeTo(box.width - inset, 0.01));
      expect(right.$1.dx, greaterThan(geo.cartouche.right));
      expect(left.$1.dy, closeTo(ink.center.dy, 0.01));
    });

    test('path is closed and inside the cartouche rect', () {
      final rect = Rect.fromLTWH(10, 5, 120, 30);
      final path = mushafCartouchePath(rect);
      expect(path.getBounds().left, closeTo(rect.left, 0.5));
      expect(path.getBounds().right, closeTo(rect.right, 0.5));
      expect(path.getBounds().top, closeTo(rect.top, 0.5));
      expect(path.getBounds().bottom, closeTo(rect.bottom, 0.5));
    });
  });

  group('option-I paint', () {
    test('outline is stroke-only with no fill', () {
      final geo = layoutMushafCartouche(
        box: box,
        inkRect: Rect.fromCenter(
          center: Offset(box.width / 2, box.height / 2),
          width: 100,
          height: 34,
        ),
      );
      final paint = MushafSurahCartouchePainter.strokePaint(
        Colors.black,
        geo,
      );
      expect(paint.style, PaintingStyle.stroke);
      expect(paint.color.a, closeTo(0.5, 0.02));
      expect(geo.strokeWidth, closeTo(kMushafCartoucheStroke, 1e-9));
      expect(geo.hairlineWidth, closeTo(kMushafCartoucheHairline, 1e-9));
    });

    test('shouldRepaint only on geometry/colour change', () {
      final ink = Rect.fromCenter(
        center: Offset(box.width / 2, box.height / 2),
        width: 100,
        height: 34,
      );
      final a = MushafSurahCartouchePainter(
        geometry: layoutMushafCartouche(box: box, inkRect: ink),
        color: Colors.black,
      );
      final b = MushafSurahCartouchePainter(
        geometry: layoutMushafCartouche(box: box, inkRect: ink),
        color: Colors.black,
      );
      expect(b.shouldRepaint(a), isFalse);
      final c = MushafSurahCartouchePainter(
        geometry: layoutMushafCartouche(box: box, inkRect: ink),
        color: Colors.white,
      );
      expect(c.shouldRepaint(a), isTrue);
    });
  });

  test('framed header stays within its 15-row slot', () {
    for (final surah in [1, 2, 9, 110, 105, 114]) {
      final layout = layoutSurahNameInk(
        surahId: surah,
        targetInkHeight: kMushafPageRowHeight * kSurahNameInkHeightFactor,
        maxInkWidth: kMushafPageLayoutWidth * kSurahNameMaxInkWidthFactor,
      );
      final ink = Rect.fromCenter(
        center: Offset(box.width / 2, box.height / 2),
        width: layout.inkWidth,
        height: layout.inkHeight,
      );
      final geo = layoutMushafCartouche(box: box, inkRect: ink);
      expect(geo.cartouche.top, greaterThanOrEqualTo(0));
      expect(geo.cartouche.bottom, lessThanOrEqualTo(box.height));
    }
  });
}
