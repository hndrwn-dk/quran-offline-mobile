/// Preprocessing for Quran Foundation uthmani_tajweed HTML before span parsing.
///
/// Does not invent tajweed rules. Only aliases legacy `<rule>` tags to
/// `<tajweed>`. Coloring follows Foundation `<tajweed class=…>` tags.
class TajweedHtml {
  TajweedHtml._();

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
  /// Used by Surah reader, Juz reader, and explore sheet via [TajweedParser].
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
    return text;
  }
}
