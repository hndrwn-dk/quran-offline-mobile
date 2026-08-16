/// Preprocessing for Quran Foundation uthmani_tajweed HTML before span parsing.
///
/// Does not invent tajweed rules. Only aliases legacy `<rule>` tags and strips
/// a non-display marker. Coloring follows Foundation `<tajweed class=…>` tags.
class TajweedHtml {
  TajweedHtml._();

  /// U+06E1 appears in some word-level dumps; it is not a Foundation rule tag.
  static const String tafkhimMarker = '\u06E1';

  /// Identity for Reader/Juz: on-screen Arabic must match JSON `ar`.
  /// Search still uses [ArabicSearchNormalizer], not this.
  /// Mushaf pages use QPC V2 15-line glyph fonts, not this path.
  static String normalizeArabicForDisplay(String arabic) => arabic;

  /// Strips tags only. Does not rewrite letters.
  static String plainArabicFromHtml(String tajweedHtml) {
    return tajweedHtml
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Single global preprocessing pipeline for every verse `tj` field.
  /// Used by Surah reader, Juz reader, Mushaf, and explore sheet via [TajweedParser].
  static String prepareForParsing(String html) {
    var text = html;
    text = text.replaceAllMapped(
      RegExp(r'<rule\s+class=', caseSensitive: false),
      (_) => '<tajweed class=',
    );
    text = text.replaceAll(
      RegExp(r'</rule>', caseSensitive: false),
      '</tajweed>',
    );
    text = text.replaceAll(tafkhimMarker, '');
    return text;
  }
}
