/// Preprocessing for Quran Foundation uthmani_tajweed HTML before span parsing.
///
/// Does not invent tajweed rules. Only aliases legacy `<rule>` tags and strips
/// a non-display marker. Coloring follows Foundation `<tajweed class=…>` tags.
class TajweedHtml {
  TajweedHtml._();

  /// U+06E1 appears in some word-level dumps; it is not a Foundation rule tag.
  static const String tafkhimMarker = '\u06E1';

  /// Normalizes Arabic text for display only (font rendering).
  ///
  /// Keeps U+0670 (superscript alef) — Foundation madda tags use `ـٰ`.
  static String normalizeArabicForDisplay(String arabic) {
    return arabic
        .replaceAll('\u0671', '\u0627')
        .replaceAll('\u0672', '\u0627')
        .replaceAll('\u065F', '')
        .replaceAll('\u06A0', '')
        .replaceAll('\u06DD', '')
        .replaceAll('\u06D9', '')
        .replaceAll('\u06DA', '')
        .replaceAll('\u06DF', '\u06E0');
  }

  /// Strips tags and normalizes for plain display.
  static String plainArabicFromHtml(String tajweedHtml) {
    final stripped = tajweedHtml
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return normalizeArabicForDisplay(stripped);
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
