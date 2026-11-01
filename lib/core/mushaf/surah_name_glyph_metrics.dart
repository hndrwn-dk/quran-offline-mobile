// GENERATED FILE - do not edit by hand.
// Regenerate with: python tools/generate_surah_name_glyph_metrics.py
//
// Ink bounds of the SurahNameV2 ornament ligatures, in font units.
// SurahNameV2 has large empty ascent/descent; the Mushaf header sizes the
// glyph by these ink bounds so every surah name has the same visual height.

const double kSurahNameGlyphUnitsPerEm = 1024;

/// Ink box of one surah-name ligature, in font units.
///
/// [yMax] and [yMin] are measured from the baseline (font y-up). This font
/// keeps the whole ink above the baseline, so both are positive.
class SurahNameGlyphInk {
  const SurahNameGlyphInk({
    required this.surahId,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });

  final int surahId;
  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;

  double get inkWidthUnits => (xMax - xMin).toDouble();

  double get inkHeightUnits => (yMax - yMin).toDouble();
}

/// Text sequence that ligates to the surah ornament.
///
/// Surah 33 is the only surah whose ligature is not `surahNNN`.
String surahNameGlyphText(int surahId) {
  if (surahId == 33) return '033';
  return 'surah${surahId.toString().padLeft(3, '0')}';
}

/// Indexed by `surahId - 1`.
const List<SurahNameGlyphInk> kSurahNameGlyphInk = [
  SurahNameGlyphInk(surahId: 1, xMin: 26, yMin: 77, xMax: 2136, yMax: 854),
  SurahNameGlyphInk(surahId: 2, xMin: 26, yMin: 81, xMax: 2022, yMax: 849),
  SurahNameGlyphInk(surahId: 3, xMin: 26, yMin: 81, xMax: 2222, yMax: 854),
  SurahNameGlyphInk(surahId: 4, xMin: 26, yMin: 81, xMax: 1992, yMax: 849),
  SurahNameGlyphInk(surahId: 5, xMin: 26, yMin: 81, xMax: 2057, yMax: 854),
  SurahNameGlyphInk(surahId: 6, xMin: 26, yMin: 77, xMax: 1980, yMax: 854),
  SurahNameGlyphInk(surahId: 7, xMin: 26, yMin: 67, xMax: 2292, yMax: 849),
  SurahNameGlyphInk(surahId: 8, xMin: 26, yMin: 81, xMax: 2197, yMax: 854),
  SurahNameGlyphInk(surahId: 9, xMin: 26, yMin: 67, xMax: 1901, yMax: 863),
  SurahNameGlyphInk(surahId: 10, xMin: 26, yMin: 86, xMax: 1945, yMax: 849),
  SurahNameGlyphInk(surahId: 11, xMin: 26, yMin: 81, xMax: 1685, yMax: 849),
  SurahNameGlyphInk(surahId: 12, xMin: 26, yMin: 81, xMax: 2106, yMax: 849),
  SurahNameGlyphInk(surahId: 13, xMin: 26, yMin: 77, xMax: 1789, yMax: 858),
  SurahNameGlyphInk(surahId: 14, xMin: 26, yMin: 77, xMax: 2010, yMax: 858),
  SurahNameGlyphInk(surahId: 15, xMin: 26, yMin: 81, xMax: 2022, yMax: 854),
  SurahNameGlyphInk(surahId: 16, xMin: 26, yMin: 77, xMax: 1862, yMax: 854),
  SurahNameGlyphInk(surahId: 17, xMin: 26, yMin: 81, xMax: 1966, yMax: 849),
  SurahNameGlyphInk(surahId: 18, xMin: 26, yMin: 60, xMax: 2127, yMax: 868),
  SurahNameGlyphInk(surahId: 19, xMin: 26, yMin: 86, xMax: 1540, yMax: 849),
  SurahNameGlyphInk(surahId: 20, xMin: 26, yMin: 86, xMax: 1589, yMax: 849),
  SurahNameGlyphInk(surahId: 21, xMin: 26, yMin: 81, xMax: 1936, yMax: 854),
  SurahNameGlyphInk(surahId: 22, xMin: 26, yMin: 81, xMax: 1724, yMax: 849),
  SurahNameGlyphInk(surahId: 23, xMin: 26, yMin: 60, xMax: 2318, yMax: 868),
  SurahNameGlyphInk(surahId: 24, xMin: 26, yMin: 67, xMax: 1745, yMax: 863),
  SurahNameGlyphInk(surahId: 25, xMin: 26, yMin: 77, xMax: 2015, yMax: 849),
  SurahNameGlyphInk(surahId: 26, xMin: 26, yMin: 60, xMax: 2252, yMax: 863),
  SurahNameGlyphInk(surahId: 27, xMin: 26, yMin: 67, xMax: 1850, yMax: 858),
  SurahNameGlyphInk(surahId: 28, xMin: 26, yMin: 77, xMax: 2218, yMax: 849),
  SurahNameGlyphInk(surahId: 29, xMin: 26, yMin: 67, xMax: 2513, yMax: 858),
  SurahNameGlyphInk(surahId: 30, xMin: 26, yMin: 77, xMax: 1927, yMax: 858),
  SurahNameGlyphInk(surahId: 31, xMin: 26, yMin: 81, xMax: 1915, yMax: 854),
  SurahNameGlyphInk(surahId: 32, xMin: 26, yMin: 60, xMax: 2066, yMax: 868),
  SurahNameGlyphInk(surahId: 33, xMin: 26, yMin: 77, xMax: 2271, yMax: 854),
  SurahNameGlyphInk(surahId: 34, xMin: 26, yMin: 86, xMax: 1831, yMax: 849),
  SurahNameGlyphInk(surahId: 35, xMin: 26, yMin: 77, xMax: 1885, yMax: 854),
  SurahNameGlyphInk(surahId: 36, xMin: 26, yMin: 86, xMax: 1701, yMax: 845),
  SurahNameGlyphInk(surahId: 37, xMin: 26, yMin: 81, xMax: 2166, yMax: 849),
  SurahNameGlyphInk(surahId: 38, xMin: 26, yMin: 86, xMax: 1650, yMax: 845),
  SurahNameGlyphInk(surahId: 39, xMin: 26, yMin: 72, xMax: 1710, yMax: 854),
  SurahNameGlyphInk(surahId: 40, xMin: 26, yMin: 81, xMax: 1736, yMax: 845),
  SurahNameGlyphInk(surahId: 41, xMin: 26, yMin: 86, xMax: 2201, yMax: 849),
  SurahNameGlyphInk(surahId: 42, xMin: 26, yMin: 72, xMax: 2287, yMax: 858),
  SurahNameGlyphInk(surahId: 43, xMin: 26, yMin: 77, xMax: 2187, yMax: 854),
  SurahNameGlyphInk(surahId: 44, xMin: 26, yMin: 81, xMax: 2206, yMax: 849),
  SurahNameGlyphInk(surahId: 45, xMin: 26, yMin: 77, xMax: 1920, yMax: 849),
  SurahNameGlyphInk(surahId: 46, xMin: 26, yMin: 81, xMax: 2318, yMax: 849),
  SurahNameGlyphInk(surahId: 47, xMin: 26, yMin: 86, xMax: 1745, yMax: 849),
  SurahNameGlyphInk(surahId: 48, xMin: 26, yMin: 77, xMax: 2006, yMax: 854),
  SurahNameGlyphInk(surahId: 49, xMin: 26, yMin: 77, xMax: 2462, yMax: 854),
  SurahNameGlyphInk(surahId: 50, xMin: 26, yMin: 86, xMax: 1375, yMax: 845),
  SurahNameGlyphInk(surahId: 51, xMin: 26, yMin: 67, xMax: 2287, yMax: 858),
  SurahNameGlyphInk(surahId: 52, xMin: 26, yMin: 51, xMax: 1971, yMax: 879),
  SurahNameGlyphInk(surahId: 53, xMin: 26, yMin: 67, xMax: 1824, yMax: 863),
  SurahNameGlyphInk(surahId: 54, xMin: 26, yMin: 51, xMax: 1766, yMax: 875),
  SurahNameGlyphInk(surahId: 55, xMin: 26, yMin: 60, xMax: 1957, yMax: 863),
  SurahNameGlyphInk(surahId: 56, xMin: 26, yMin: 81, xMax: 2092, yMax: 845),
  SurahNameGlyphInk(surahId: 57, xMin: 26, yMin: 77, xMax: 1927, yMax: 854),
  SurahNameGlyphInk(surahId: 58, xMin: 26, yMin: 56, xMax: 2141, yMax: 868),
  SurahNameGlyphInk(surahId: 59, xMin: 26, yMin: 56, xMax: 1927, yMax: 868),
  SurahNameGlyphInk(surahId: 60, xMin: 26, yMin: 67, xMax: 2266, yMax: 863),
  SurahNameGlyphInk(surahId: 61, xMin: 26, yMin: 77, xMax: 2097, yMax: 849),
  SurahNameGlyphInk(surahId: 62, xMin: 26, yMin: 81, xMax: 1957, yMax: 849),
  SurahNameGlyphInk(surahId: 63, xMin: 26, yMin: 67, xMax: 2457, yMax: 858),
  SurahNameGlyphInk(surahId: 64, xMin: 26, yMin: 81, xMax: 2145, yMax: 849),
  SurahNameGlyphInk(surahId: 65, xMin: 26, yMin: 72, xMax: 2341, yMax: 854),
  SurahNameGlyphInk(surahId: 66, xMin: 26, yMin: 77, xMax: 2001, yMax: 849),
  SurahNameGlyphInk(surahId: 67, xMin: 26, yMin: 77, xMax: 1920, yMax: 849),
  SurahNameGlyphInk(surahId: 68, xMin: 26, yMin: 72, xMax: 1915, yMax: 854),
  SurahNameGlyphInk(surahId: 69, xMin: 26, yMin: 72, xMax: 1880, yMax: 858),
  SurahNameGlyphInk(surahId: 70, xMin: 26, yMin: 67, xMax: 1931, yMax: 858),
  SurahNameGlyphInk(surahId: 71, xMin: 26, yMin: 81, xMax: 1759, yMax: 845),
  SurahNameGlyphInk(surahId: 72, xMin: 26, yMin: 56, xMax: 1766, yMax: 868),
  SurahNameGlyphInk(surahId: 73, xMin: 26, yMin: 51, xMax: 2071, yMax: 875),
  SurahNameGlyphInk(surahId: 74, xMin: 26, yMin: 81, xMax: 1885, yMax: 849),
  SurahNameGlyphInk(surahId: 75, xMin: 26, yMin: 72, xMax: 1906, yMax: 849),
  SurahNameGlyphInk(surahId: 76, xMin: 26, yMin: 86, xMax: 2197, yMax: 849),
  SurahNameGlyphInk(surahId: 77, xMin: 26, yMin: 56, xMax: 2257, yMax: 868),
  SurahNameGlyphInk(surahId: 78, xMin: 26, yMin: 77, xMax: 1785, yMax: 854),
  SurahNameGlyphInk(surahId: 79, xMin: 26, yMin: 72, xMax: 2392, yMax: 854),
  SurahNameGlyphInk(surahId: 80, xMin: 26, yMin: 77, xMax: 1996, yMax: 845),
  SurahNameGlyphInk(surahId: 81, xMin: 26, yMin: 51, xMax: 2001, yMax: 875),
  SurahNameGlyphInk(surahId: 82, xMin: 26, yMin: 67, xMax: 2248, yMax: 863),
  SurahNameGlyphInk(surahId: 83, xMin: 26, yMin: 67, xMax: 2522, yMax: 858),
  SurahNameGlyphInk(surahId: 84, xMin: 26, yMin: 72, xMax: 2492, yMax: 858),
  SurahNameGlyphInk(surahId: 85, xMin: 26, yMin: 77, xMax: 2127, yMax: 849),
  SurahNameGlyphInk(surahId: 86, xMin: 26, yMin: 72, xMax: 2092, yMax: 849),
  SurahNameGlyphInk(surahId: 87, xMin: 26, yMin: 72, xMax: 1927, yMax: 854),
  SurahNameGlyphInk(surahId: 88, xMin: 26, yMin: 72, xMax: 2436, yMax: 854),
  SurahNameGlyphInk(surahId: 89, xMin: 26, yMin: 77, xMax: 2045, yMax: 849),
  SurahNameGlyphInk(surahId: 90, xMin: 26, yMin: 81, xMax: 1836, yMax: 849),
  SurahNameGlyphInk(surahId: 91, xMin: 26, yMin: 42, xMax: 2443, yMax: 884),
  SurahNameGlyphInk(surahId: 92, xMin: 26, yMin: 67, xMax: 1896, yMax: 863),
  SurahNameGlyphInk(surahId: 93, xMin: 26, yMin: 56, xMax: 2050, yMax: 875),
  SurahNameGlyphInk(surahId: 94, xMin: 26, yMin: 42, xMax: 2145, yMax: 889),
  SurahNameGlyphInk(surahId: 95, xMin: 26, yMin: 72, xMax: 1875, yMax: 858),
  SurahNameGlyphInk(surahId: 96, xMin: 26, yMin: 77, xMax: 1915, yMax: 854),
  SurahNameGlyphInk(surahId: 97, xMin: 26, yMin: 77, xMax: 1831, yMax: 854),
  SurahNameGlyphInk(surahId: 98, xMin: 26, yMin: 67, xMax: 1880, yMax: 863),
  SurahNameGlyphInk(surahId: 99, xMin: 26, yMin: 77, xMax: 1980, yMax: 858),
  SurahNameGlyphInk(surahId: 100, xMin: 26, yMin: 77, xMax: 2462, yMax: 858),
  SurahNameGlyphInk(surahId: 101, xMin: 26, yMin: 77, xMax: 2206, yMax: 858),
  SurahNameGlyphInk(surahId: 102, xMin: 26, yMin: 72, xMax: 2050, yMax: 854),
  SurahNameGlyphInk(surahId: 103, xMin: 26, yMin: 67, xMax: 2166, yMax: 863),
  SurahNameGlyphInk(surahId: 104, xMin: 26, yMin: 77, xMax: 1920, yMax: 854),
  SurahNameGlyphInk(surahId: 105, xMin: 26, yMin: 77, xMax: 1910, yMax: 854),
  SurahNameGlyphInk(surahId: 106, xMin: 26, yMin: 81, xMax: 2057, yMax: 849),
  SurahNameGlyphInk(surahId: 107, xMin: 26, yMin: 77, xMax: 2287, yMax: 854),
  SurahNameGlyphInk(surahId: 108, xMin: 26, yMin: 46, xMax: 1966, yMax: 879),
  SurahNameGlyphInk(surahId: 109, xMin: 26, yMin: 77, xMax: 2336, yMax: 849),
  SurahNameGlyphInk(surahId: 110, xMin: 26, yMin: 81, xMax: 1992, yMax: 849),
  SurahNameGlyphInk(surahId: 111, xMin: 26, yMin: 77, xMax: 2122, yMax: 845),
  SurahNameGlyphInk(surahId: 112, xMin: 26, yMin: 81, xMax: 2478, yMax: 845),
  SurahNameGlyphInk(surahId: 113, xMin: 26, yMin: 77, xMax: 1862, yMax: 854),
  SurahNameGlyphInk(surahId: 114, xMin: 26, yMin: 81, xMax: 2041, yMax: 845),
];

/// Ink metrics for [surahId], or null outside 1..114.
SurahNameGlyphInk? surahNameGlyphInkFor(int surahId) {
  if (surahId < 1 || surahId > kSurahNameGlyphInk.length) return null;
  return kSurahNameGlyphInk[surahId - 1];
}
