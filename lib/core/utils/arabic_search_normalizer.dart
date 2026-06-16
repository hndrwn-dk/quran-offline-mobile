/// Normalizes Arabic for verse search matching (not for altering stored Quran text).
class ArabicSearchNormalizer {
  ArabicSearchNormalizer._();

  static final _arabicScript = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  static final _tashkeel = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );

  static bool containsArabic(String text) {
    return _arabicScript.hasMatch(text);
  }

  /// Strips diacritics and unifies common letter variants for substring search.
  static String normalizeForSearch(String input) {
    var s = input.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll(_tashkeel, '');
    s = s.replaceAll('\u0640', ''); // tatweel
    s = s.replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), '\u0627');
    s = s.replaceAll('\u0649', '\u064A'); // alif maqsura -> yaa
    s = s.replaceAll('\u06DF', '');
    s = s.replaceAll('\u06DD', ''); // end of ayah mark
    return s.trim();
  }

  /// Short display snippet for search result titles.
  static String snippetForDisplay(String arabic, {int maxLength = 72}) {
    final plain = arabic.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    if (plain.length <= maxLength) return plain;
    return '…${plain.substring(plain.length - maxLength + 1)}';
  }
}
