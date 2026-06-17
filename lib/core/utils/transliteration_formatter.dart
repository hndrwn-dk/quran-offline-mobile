/// Safe readability pass for Quran.com-style transliteration (field `tl`).
///
/// Does NOT overwrite or replace the original `tl`. Produces a derived string
/// `tl_readable` for display when "Readable" style is selected.
///
/// Rules applied:
/// - R1: Remove ASCII apostrophe (') used for syllable splitting.
/// - R2: Collapse multiple spaces; trim.
/// - R3: Normalize article hyphen (l-l -> ll) for smoother reading.
/// - R4: Waqf (waqf): drop final short vowel so the ayah ends "closed" (patah/tutup).
/// - Preserves diacritics (ā ī ū ṣ ḥ ʿ etc.) and does not infer tajweed.
library;

/// Style of transliteration to show in the UI.
enum TransliterationStyle {
  /// Original Quran.com transliteration (raw `tl`).
  original,

  /// Readable pass: smoother, no syllable apostrophe, normalized spacing/hyphen.
  readable,
}

/// Formatter that produces a readable version of Quran.com transliteration.
class TransliterationFormatter {
  TransliterationFormatter._();

  /// Produces readable transliteration from raw [tlRaw].
  /// Optionally [tajweedHtml] can be passed for future use (e.g. laam shamsiyah);
  /// currently only deterministic text rules are applied.
  static String toReadable(String tlRaw, {String? tajweedHtml}) {
    if (tlRaw.isEmpty) return tlRaw;
    String s = tlRaw;

    // R1: Remove syllable-breaking apostrophe (ASCII ' only). Preserve ʿ (ain).
    // Pattern: letter + ' + letter -> letter + letter (e.g. bis'mi -> bismi).
    s = _removeSyllableApostrophe(s);

    // R2: Collapse multiple spaces into one; trim.
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    // R3: Normalize article hyphen: l-l -> ll (e.g. l-lahi -> llahi).
    s = _normalizeArticleHyphen(s);

    // R4: Waqf - drop final short vowel so end of ayah is "closed" (patah/tutup).
    s = _applyWaqf(s);

    return s;
  }

  /// R4: Waqf - drop final short vowel of the last word only (ayat ends closed).
  /// E.g. "... l-raḥīmi" -> "... l-raḥīm", "... l-'ālamīna" -> "... l-'ālamīn".
  static String _applyWaqf(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return s;
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.isEmpty) return s;
    const vowels = 'aiuāīū';
    String lastWord = words.last;
    if (lastWord.isNotEmpty && vowels.contains(lastWord[lastWord.length - 1])) {
      lastWord = lastWord.substring(0, lastWord.length - 1);
      words[words.length - 1] = lastWord;
      return words.join(' ');
    }
    return s;
  }

  /// R1: Remove ASCII apostrophe used as syllable split.
  /// (\w)'(\w) -> $1$2. Multiple passes until no change.
  static String _removeSyllableApostrophe(String s) {
    String current = s;
    String next = current.replaceAllMapped(
      RegExp(r"(\w)'(\w)"),
      (m) => '${m[1]}${m[2]}',
    );
    while (next != current) {
      current = next;
      next = current.replaceAllMapped(
        RegExp(r"(\w)'(\w)"),
        (m) => '${m[1]}${m[2]}',
      );
    }
    return current;
  }

  /// R3: l-l -> ll for definite article (e.g. l-lahi -> llahi).
  static String _normalizeArticleHyphen(String s) {
    return s.replaceAll(RegExp(r'l-l'), 'll');
  }

  /// Returns the transliteration string to display based on [style].
  /// [tlRaw] is the original `tl` from data; [tajweedHtml] is optional (verse tajweed).
  static String displayTransliteration({
    required String? tlRaw,
    required TransliterationStyle style,
    String? tajweedHtml,
  }) {
    if (tlRaw == null || tlRaw.isEmpty) return '';
    switch (style) {
      case TransliterationStyle.original:
      case TransliterationStyle.readable:
        return toReadable(tlRaw, tajweedHtml: tajweedHtml);
    }
  }

  /// Tajweed transliteration display — uses `tl_tj` with boundary fixes.
  ///
  /// Scholarly `tl` is fallback only when `tl_tj` is missing.
  static String displayTajweedTransliteration({
    required String? tlRaw,
    required String? tlTjRaw,
    String? tajweedHtml,
  }) {
    if (tlTjRaw != null && tlTjRaw.trim().isNotEmpty) {
      return formatTajweedTransliteration(tlTjRaw.trim(), tlRaw: tlRaw);
    }
    if (tlRaw != null && tlRaw.trim().isNotEmpty) {
      return toReadable(tlRaw.trim(), tajweedHtml: tajweedHtml);
    }
    return '';
  }

  /// Fixes systematic `tl_tj` romanizer artifacts (38:70: yuwhan→yuwha, etc.).
  static String formatTajweedTransliteration(
    String tlTj, {
    String? tlRaw,
  }) {
    if (tlTj.isEmpty) return tlTj;
    var s = tlTj;

    s = s.replaceAll(RegExp(r'\byuwhan\b', caseSensitive: false), 'yuwha');
    s = s.replaceAll(RegExp(r'\bannamma\b', caseSensitive: false), 'annnama');

    final tl = tlRaw ?? '';
    if (RegExp(r'\bilayya\b', caseSensitive: false).hasMatch(tl)) {
      s = s.replaceAll(RegExp(r'\bilaa\b', caseSensitive: false), 'ilayya');
    }
    if (tl.contains('illā')) {
      s = s.replaceAll(RegExp(r'\billa\b', caseSensitive: false), 'illā');
    }

    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @Deprecated('Use formatTajweedTransliteration')
  static String fromTajweedWords(String tlTj) => formatTajweedTransliteration(tlTj);
}
