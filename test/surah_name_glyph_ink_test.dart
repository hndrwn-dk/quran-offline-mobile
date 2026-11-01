import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/surah_name_glyph_metrics.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';

const _sampleSurahs = [1, 2, 3, 50, 112, 113, 114];

double get _targetInkHeight => kMushafPageRowHeight * kSurahNameInkHeightFactor;
double get _maxInkWidth =>
    kMushafPageLayoutWidth * kSurahNameMaxInkWidthFactor;

void main() {
  group('ink metrics table', () {
    test('covers all 114 surahs with usable ink', () {
      expect(kSurahNameGlyphInk.length, 114);
      for (final ink in kSurahNameGlyphInk) {
        expect(ink.inkHeightUnits, greaterThan(0), reason: 'surah ${ink.surahId}');
        expect(ink.inkWidthUnits, greaterThan(0), reason: 'surah ${ink.surahId}');
      }
      expect(kSurahNameGlyphUnitsPerEm, 1024);
    });

    test('surah 33 uses the font short ligature', () {
      expect(surahNameGlyphText(33), '033');
      expect(surahNameGlyphText(1), 'surah001');
      expect(surahNameGlyphText(114), 'surah114');
    });

    test('ink height is much smaller than the font box (regression cause)', () {
      // The ornament ink is ~0.74-0.83 em while the line box is 1 em plus
      // ascent/descent, which is why the old line-box fit shrank it twice.
      for (final surah in _sampleSurahs) {
        final ink = surahNameGlyphInkFor(surah)!;
        expect(ink.inkHeightUnits / kSurahNameGlyphUnitsPerEm, lessThan(0.85));
      }
    });
  });

  group('ink layout', () {
    test('every sampled surah gets the same target ink height', () {
      for (final surah in _sampleSurahs) {
        final layout = layoutSurahNameInk(
          surahId: surah,
          targetInkHeight: _targetInkHeight,
          maxInkWidth: _maxInkWidth,
        );
        expect(layout.inkHeight, closeTo(_targetInkHeight, _targetInkHeight * 0.01),
            reason: 'surah $surah');
        expect(layout.inkWidth, lessThanOrEqualTo(_maxInkWidth + 0.01),
            reason: 'surah $surah');
      }
    });

    test('ink heights are equal across surahs (no visual drift)', () {
      final heights = [
        for (final surah in _sampleSurahs)
          layoutSurahNameInk(
            surahId: surah,
            targetInkHeight: _targetInkHeight,
            maxInkWidth: _maxInkWidth,
          ).inkHeight,
      ];
      for (final height in heights) {
        expect(height, closeTo(heights.first, 0.01));
      }
    });

    test('ink never leaves its row (no overlap, no clipping)', () {
      const slotHeight = kMushafPageRowHeight;
      for (final surah in _sampleSurahs) {
        final layout = layoutSurahNameInk(
          surahId: surah,
          targetInkHeight: _targetInkHeight,
          maxInkWidth: _maxInkWidth,
        );
        final baseline = layout.baselineForSlot(slotHeight);
        final inkTop = baseline - layout.inkTopAboveBaseline;
        final inkBottom = baseline - layout.inkBottomAboveBaseline;
        expect(inkTop, greaterThanOrEqualTo(-0.01), reason: 'surah $surah');
        expect(inkBottom, lessThanOrEqualTo(slotHeight + 0.01),
            reason: 'surah $surah');
        expect(inkBottom - inkTop, closeTo(layout.inkHeight, 0.01));
      }
    });

    test('wide names are scaled down by width only', () {
      const narrow = 60.0;
      final natural = layoutSurahNameInk(
        surahId: 2,
        targetInkHeight: _targetInkHeight,
        maxInkWidth: 10000,
      );
      final clamped = layoutSurahNameInk(
        surahId: 2,
        targetInkHeight: _targetInkHeight,
        maxInkWidth: narrow,
      );
      expect(clamped.inkWidth, closeTo(narrow, 0.01));
      expect(clamped.inkHeight, lessThan(natural.inkHeight));
      expect(
        clamped.inkHeight / natural.inkHeight,
        closeTo(narrow / natural.inkWidth, 0.001),
      );
    });

    test('empty layout for unknown surahs', () {
      expect(layoutSurahNameInk(surahId: 0, targetInkHeight: 20, maxInkWidth: 100).isEmpty,
          isTrue);
      expect(layoutSurahNameInk(surahId: 115, targetInkHeight: 20, maxInkWidth: 100).isEmpty,
          isTrue);
    });
  });

  group('ink glyph widget', () {
    testWidgets('paints inside a full QPC row without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: kMushafPageLayoutWidth,
                height: kMushafPageRowHeight,
                child: SurahNameMushafInkGlyph(
                  surahId: 2,
                  color: Colors.black,
                  targetInkHeight: _targetInkHeight,
                  maxInkWidth: _maxInkWidth,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(SurahNameMushafInkGlyph)),
        const Size(kMushafPageLayoutWidth, kMushafPageRowHeight),
      );
    });

    testWidgets('renders every sampled surah without exceptions',
        (tester) async {
      for (final surah in _sampleSurahs) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: kMushafPageLayoutWidth,
                  height: kMushafPageRowHeight,
                  child: SurahNameMushafInkGlyph(
                    surahId: surah,
                    color: Colors.black,
                    targetInkHeight: _targetInkHeight,
                    maxInkWidth: _maxInkWidth,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'surah $surah');
      }
    });
  });
}
