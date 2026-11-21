import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<({String glyphText, String fontFamily, bool justify})> lines(
    String family,
  ) =>
      [
        (glyphText: 'abcdefghij' * 4, fontFamily: family, justify: false),
        (glyphText: 'klmnop' * 5, fontFamily: family, justify: false),
      ];

  setUp(clearQpcV2GlyphFitCache);

  test('cached page size equals the uncached computation', () {
    final uncached = computeQpcV2PageFontSize(
      lines: lines('p3'),
      maxFontSize: 38,
      maxWidth: 300,
    );
    final cached = computeQpcV2PageFontSizeCached(
      cacheKey: qpcV2PageFitCacheKey(
        fontFamily: 'p3',
        maxFontSize: 38,
        maxWidth: 300,
      ),
      lines: lines('p3'),
      maxFontSize: 38,
      maxWidth: 300,
    );
    expect(cached, uncached);
  });

  test('evicting one family keeps the other pages cached', () {
    for (final family in ['p3', 'p4']) {
      computeQpcV2PageFontSizeCached(
        cacheKey: qpcV2PageFitCacheKey(
          fontFamily: family,
          maxFontSize: 38,
          maxWidth: 300,
        ),
        lines: lines(family),
        maxFontSize: 38,
        maxWidth: 300,
      );
    }
    expect(qpcV2GlyphFitCacheContains(fontFamily: 'p3'), isTrue);
    expect(qpcV2GlyphFitCacheContains(fontFamily: 'p4'), isTrue);

    evictQpcV2GlyphFitCacheForFamily('p3');

    expect(qpcV2GlyphFitCacheContains(fontFamily: 'p3'), isFalse);
    expect(qpcV2GlyphFitCacheContains(fontFamily: 'p4'), isTrue);
  });

  test('a family that is a prefix of another is evicted alone', () {
    for (final family in ['p3', 'p30']) {
      computeQpcV2PageFontSizeCached(
        cacheKey: qpcV2PageFitCacheKey(
          fontFamily: family,
          maxFontSize: 38,
          maxWidth: 300,
        ),
        lines: lines(family),
        maxFontSize: 38,
        maxWidth: 300,
      );
    }
    evictQpcV2GlyphFitCacheForFamily('p3');
    expect(qpcV2GlyphFitCacheContains(fontFamily: 'p30'), isTrue);
  });
}
