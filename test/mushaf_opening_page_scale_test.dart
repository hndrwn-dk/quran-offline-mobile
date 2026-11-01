import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';

({String glyphText, String fontFamily, bool justify}) _line(String text) => (
      glyphText: text,
      fontFamily: 'UpcV2Page1',
      justify: false,
    );

void main() {
  test('both opening pages get the same scale', () {
    final page1 = [_line('a' * 40), _line('a' * 30)];
    final page2 = [_line('a' * 35), _line('a' * 20)];

    final forward = computeOpeningPageScale(lines: [...page1, ...page2]);
    final reverse = computeOpeningPageScale(lines: [...page2, ...page1]);
    expect(forward, closeTo(reverse, 1e-9));
    expect(forward, greaterThanOrEqualTo(1.0));
  });

  test('the widest line still fits the reference text width', () {
    final lines = [_line('a' * 10), _line('a' * 4)];
    final scale = computeOpeningPageScale(lines: lines);
    final fitted = computeQpcV2PageFontSize(
      lines: lines,
      maxFontSize: kMushafPageFontSize * scale,
      maxWidth: kMushafPageLayoutWidth,
    );
    expect(fitted, closeTo(kMushafPageFontSize * scale, 0.6));
  });

  test('eight rows plus one row of breathing room fit the page height', () {
    final scale = computeOpeningPageScale(lines: [_line('a' * 10)]);
    expect(
      8 * kMushafPageRowHeight * scale + kMushafPageRowHeight,
      lessThanOrEqualTo(kMushafPageLayoutHeight + 0.01),
    );
  });

  test('short lines are height-limited and capped', () {
    final scale = computeOpeningPageScale(lines: [_line('a')]);
    final heightLimited = (kMushafPageLayoutHeight - kMushafPageRowHeight) /
        (8 * kMushafPageRowHeight);
    expect(scale, closeTo(heightLimited.clamp(1.0, 2.0), 1e-9));
    expect(scale, lessThanOrEqualTo(2.0));
  });

  test('normal pages keep scale 1 when the scale is not applied', () {
    // Sanity: the fit helper does not silently enlarge beyond its cap.
    final fitted = computeQpcV2PageFontSize(
      lines: [_line('a' * 10)],
      maxFontSize: kMushafPageFontSize,
      maxWidth: kMushafPageLayoutWidth,
    );
    expect(fitted, closeTo(kMushafPageFontSize, 1e-9));
  });
}

