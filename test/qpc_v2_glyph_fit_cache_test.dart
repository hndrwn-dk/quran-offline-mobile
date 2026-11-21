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
}
