import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/mushaf_sheet_layout.dart';

/// 1.0.23 vertical chrome with the bars hidden: exercises the never-shrink
/// floor algorithm on the full window (normal mode uses the same algorithm).
const _focusSpreadChrome = 6.0; // top padding 6, no badge
const _focusSingleChrome = 0.0;

MushafSheetLayout _focusSpread(Size window) => resolveMushafSheetLayout(
      area: window,
      pageCount: 2,
      floor: mushafLegacyTextFrame(
        area: window,
        pageCount: 2,
        verticalChrome: _focusSpreadChrome,
      ),
    );

void main() {
  group('baseline (1.0.23) font sizes', () {
    test('Fold focus spread 933x704 is ~27.6dp', () {
      final floor = mushafLegacyTextFrame(
        area: const Size(933, 704),
        pageCount: 2,
        verticalChrome: _focusSpreadChrome,
      );
      expect(kMushafPageFontSize * mushafPageScaleFor(floor),
          closeTo(27.66, 0.05));
    });
  });

  group('never shrink', () {
    for (final window in const [
      Size(933, 704),
      Size(955, 860),
      Size(1024, 768),
      Size(1280, 800),
      Size(840, 600),
    ]) {
      test('floor: spread $window keeps the 1.0.23 text size', () {
        final floor = mushafLegacyTextFrame(
          area: window,
          pageCount: 2,
          verticalChrome: _focusSpreadChrome,
        );
        final layout = _focusSpread(window);
        expect(layout.textSize.width, greaterThanOrEqualTo(floor.width - 0.01));
        expect(layout.textSize.width / layout.textSize.height,
            closeTo(kMushafPageAspectRatio, 1e-6));
      });
    }

    for (final window in const [Size(704, 933), Size(800, 1280)]) {
      test('floor: single $window keeps the 1.0.23 text size', () {
        final floor = mushafLegacyTextFrame(
          area: window,
          pageCount: 1,
          verticalChrome: _focusSingleChrome,
        );
        final layout = resolveMushafSheetLayout(
          area: window,
          pageCount: 1,
          floor: floor,
        );
        expect(layout.textSize.width, greaterThanOrEqualTo(floor.width - 0.01));
      });
    }
  });

  group('focus mode', () {
    test('Fold focus spread: outer frame + number at 26.61dp', () {
      final layout = resolveMushafFocusSheetLayout(
        area: const Size(933, 704),
        pageCount: 2,
      );
      expect(layout.decor, MushafSheetDecor.outerFrame);
      expect(layout.decor.hasInnerFrame, isFalse);
      expect(layout.decor.hasRosettes, isFalse);
      expect(layout.showNumber, isTrue);
      expect(layout.fontSize, closeTo(26.61, 0.01));
      expect(layout.fontSize, greaterThanOrEqualTo(26.6));
      for (var i = 0; i < 2; i++) {
        final sheet = layout.sheets[i];
        final text = layout.texts[i];
        expect(text.left - sheet.left, closeTo(sheet.right - text.right, 1e-9));
      }
    });

    test('same level on every window', () {
      for (final (window, pages) in const [
        (Size(933, 704), 2),
        (Size(955, 860), 2),
        (Size(1280, 800), 2),
        (Size(704, 933), 1),
      ]) {
        final layout =
            resolveMushafFocusSheetLayout(area: window, pageCount: pages);
        expect(layout.decor, MushafSheetDecor.outerFrame, reason: '$window');
        expect(layout.showNumber, isTrue, reason: '$window');
      }
    });

    test('rosettes on the outer corners would hang off the paper', () {
      // Centred on the outer line's corner, half a rosette sticks out past
      // the sheet edge; pulling it in costs text size, so focus drops it.
      expect(kMushafFrameEdgeInset, lessThan(kMushafRosetteSize / 2));
    });
  });

  group('spine', () {
    test('frame lines at the fold keep a clear gap, no rosettes there', () {
      // Two sheets meet at the spine: outer lines 2 x spine inset apart.
      expect(kMushafFrameSpineInset * 2, greaterThanOrEqualTo(12));
      expect(kMushafFrameSpineInset, greaterThan(kMushafFrameEdgeInset));
    });
  });

  group('sheets', () {
    test('both sheets mirror their margins and meet at the spine', () {
      final layout = _focusSpread(const Size(933, 704));
      final left = layout.sheets[0];
      final right = layout.sheets[1];
      expect(left.right, closeTo(right.left, 1e-9));
      expect(left.width, closeTo(right.width, 1e-9));
      expect(left.height, closeTo(right.height, 1e-9));
      for (var i = 0; i < 2; i++) {
        final sheet = layout.sheets[i];
        final text = layout.texts[i];
        expect(text.left - sheet.left, closeTo(sheet.right - text.right, 1e-9));
      }
      // Spread centred: leftover width split between the outer sides.
      expect(left.left, closeTo(933 - right.right, 1e-9));
    });

    test('drops rosettes first, then frame lines, never the text', () {
      final roomy = resolveMushafSheetLayout(
        area: const Size(1280, 1000),
        pageCount: 2,
        floor: const Size(300, 300 / kMushafPageAspectRatio),
      );
      expect(roomy.decor, MushafSheetDecor.full);
      expect(roomy.showNumber, isTrue);

      final tight = _focusSpread(const Size(933, 704));
      expect(
          tight.decor.index, greaterThanOrEqualTo(MushafSheetDecor.full.index));
      expect(tight.fontSize, greaterThanOrEqualTo(27.6));
    });

    test('frame lines keep the ink clearance', () {
      for (final decor in MushafSheetDecor.values) {
        if (!decor.hasOuterFrame) continue;
        expect(decor.margin - decor.decorationDepth,
            greaterThanOrEqualTo(kMushafInkClearance));
        expect(decor.sideMargin - decor.spineDepth,
            greaterThanOrEqualTo(kMushafInkClearance));
        expect(decor.sideMargin - decor.decorationDepth,
            greaterThanOrEqualTo(kMushafInkClearance));
        expect(
          decor.bottomMarginWithNumber -
              decor.bottomLineDepth -
              kMushafSheetNumberGap -
              kMushafSheetNumberFrameGap -
              kMushafSheetNumberHeight,
          greaterThanOrEqualTo(-1e-9),
        );
      }
    });

    test('hinge gutter sits on the crease', () {
      final layout = resolveMushafSheetLayout(
        area: const Size(933, 704),
        pageCount: 2,
        floor: Size.zero,
        hinge: const MushafHingeLayout(leftInset: 20, gap: 10),
      );
      final gutter = (layout.sheets[0].right + layout.sheets[1].left) / 2;
      expect(gutter, closeTo(20 + (933 - 20) / 2, 1e-9));
      expect(layout.sheets[1].left - layout.sheets[0].right, closeTo(10, 1e-9));
    });
  });

  group('page stack', () {
    test('1|2: thick remaining stack left, thin read stack right', () {
      expect(mushafStackEdgeCount(pageNo: 2, onRight: false), 5);
      expect(mushafStackEdgeCount(pageNo: 1, onRight: true), 1);
    });

    test('603|604: thin left, thick right', () {
      expect(mushafStackEdgeCount(pageNo: 604, onRight: false), 1);
      expect(mushafStackEdgeCount(pageNo: 603, onRight: true), 5);
    });
  });
}
