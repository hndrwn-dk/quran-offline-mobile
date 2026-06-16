/// Preprocessing for Quran.com tajweed HTML before span parsing.
class TajweedHtml {
  TajweedHtml._();

  /// U+06E1 — sukun marker in words API; tafkhim only on isti'laa letters.
  static const String tafkhimMarker = '\u06E1';

  /// Heavy (isti'laa) letters — always colored tafkhim on quran.com.
  static const String heavyLetters = 'خصضغطقظ';

  /// Normalizes Arabic text for display only (font rendering).
  static String normalizeArabicForDisplay(String arabic) {
    return arabic
        .replaceAll('\u0671', '\u0627')
        .replaceAll('\u0672', '\u0627')
        .replaceAll('\u065F', '')
        .replaceAll('\u0670', '')
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
    text = sanitizeDisplayTagsQuranCom(text);
    text = unwrapIncorrectTafkhimTags(text);
    text = applyTafkhimMarkers(text);
    text = text.replaceAll(tafkhimMarker, '');
    text = augmentHeavyLetters(text);
    text = augmentRaTafkhim(text);
    return text;
  }

  /// Quran.com colors only the hidden noon/meem for ikhfa, and the absorbing
  /// letter for idgham — not the tanwin source or the ikhfa target letter.
  static String sanitizeDisplayTagsQuranCom(String text) {
    final tagPattern = RegExp(
      r'<tajweed\s+class=([^>\s]+)>(.*?)</tajweed>',
      dotAll: true,
      caseSensitive: false,
    );
    return text.replaceAllMapped(tagPattern, (m) {
      final cls = (m.group(1) ?? '').toLowerCase();
      final content = m.group(2) ?? '';
      final base = _firstBaseLetter(content);

      if (cls == 'ikhafa' || cls == 'ikhfa') {
        if (base == 0x0646) {
          final narrowed = _sourceLetterCluster(content, 0x0646);
          if (narrowed.isEmpty || narrowed == content) return m.group(0)!;
          final rest = content.substring(narrowed.length);
          return '<tajweed class=$cls>$narrowed</tajweed>$rest';
        }
        return content;
      }
      if (cls == 'ikhafa_shafawi') {
        if (base == 0x0645) {
          final narrowed = _sourceLetterCluster(content, 0x0645);
          if (narrowed.isEmpty || narrowed == content) return m.group(0)!;
          final rest = content.substring(narrowed.length);
          return '<tajweed class=$cls>$narrowed</tajweed>$rest';
        }
        return content;
      }
      if (cls == 'idgham_ghunnah' || cls == 'idgham_shafawi') {
        if (_hasTanwin(content)) {
          final split = _splitIdghamTanwinForDisplay(content, cls);
          if (split != null) return split;
          return content;
        }
        return m.group(0)!;
      }
      return m.group(0)!;
    });
  }

  static bool _hasTanwin(String s) {
    for (final cp in s.runes) {
      if (cp >= 0x064B && cp <= 0x064D) return true;
    }
    return false;
  }

  /// Removes tafkhim tags wrongly baked into stored data (e.g. ح، س، ل، ن).
  static String unwrapIncorrectTafkhimTags(String text) {
    final pattern = RegExp(
      r'<tajweed\s+class=tafkhim>([\u0621-\u064A\u0671][\u064B-\u0652\u0670]*)</tajweed>',
      caseSensitive: false,
    );
    return text.replaceAllMapped(pattern, (m) {
      final content = m.group(1) ?? '';
      final base = _firstBaseLetter(content);
      if (base != null && heavyLetters.contains(String.fromCharCode(base))) {
        return m.group(0)!;
      }
      return content;
    });
  }

  /// U+06E1 after isti'laa letters only → tafkhim tag; other letters drop the marker.
  static String applyTafkhimMarkers(String text) {
    final pattern = RegExp(
      r'([\u0621-\u064A\u0671][\u064B-\u0652\u0670]*)' + tafkhimMarker,
    );
    return text.replaceAllMapped(pattern, (m) {
      final content = m.group(1) ?? '';
      final base = _firstBaseLetter(content);
      if (base != null && heavyLetters.contains(String.fromCharCode(base))) {
        return '<tajweed class=tafkhim>$content</tajweed>';
      }
      return content;
    });
  }

  /// Ra with fatha/damma (or saakin after fatha/damma) → tafkhim on quran.com.
  static String augmentRaTafkhim(String html) {
    return _mapPlainSegments(html, _wrapRaInPlain);
  }

  static String _mapPlainSegments(
    String html,
    String Function(String segment) transform,
  ) {
    final tagPattern = RegExp(
      r'<tajweed\s+class=[^>]+>.*?</tajweed>|<span\s+class=[^>]+>.*?</span>',
      dotAll: true,
      caseSensitive: false,
    );

    final out = StringBuffer();
    var last = 0;
    for (final match in tagPattern.allMatches(html)) {
      if (match.start > last) {
        out.write(transform(html.substring(last, match.start)));
      }
      out.write(match.group(0));
      last = match.end;
    }
    if (last < html.length) {
      out.write(transform(html.substring(last)));
    }
    return out.toString();
  }

  static String _wrapRaInPlain(String segment) {
    if (segment.isEmpty) return segment;

    final runes = segment.runes.toList();
    final out = StringBuffer();

    for (var i = 0; i < runes.length; i++) {
      if (runes[i] != 0x631) {
        out.writeCharCode(runes[i]);
        continue;
      }

      final clusterEnd = _clusterEndAfterRa(runes, i);
      final cluster = String.fromCharCodes(runes.sublist(i, clusterEnd));
      if (_raClusterIsTafkhim(runes, i, clusterEnd)) {
        out.write('<tajweed class=tafkhim>$cluster</tajweed>');
      } else {
        out.write(cluster);
      }
      i = clusterEnd - 1;
    }
    return out.toString();
  }

  static int _clusterEndAfterRa(List<int> runes, int raIndex) {
    var j = raIndex + 1;
    while (j < runes.length && _isArabicDiacritic(runes[j])) {
      j++;
    }
    return j;
  }

  static bool _raClusterIsTafkhim(List<int> runes, int raIndex, int clusterEnd) {
    var hasShadda = false;
    int? vowel;

    for (var j = raIndex + 1; j < clusterEnd; j++) {
      final cp = runes[j];
      if (cp == 0x0651) {
        hasShadda = true;
      } else if (cp == 0x064E || cp == 0x064F || cp == 0x0650) {
        vowel = cp;
      }
    }

    if (vowel != null) {
      if (hasShadda) {
        return vowel == 0x064E || vowel == 0x064F;
      }
      return vowel == 0x064E || vowel == 0x064F;
    }

    return _raSakinIsTafkhim(runes, raIndex);
  }

  static bool _raSakinIsTafkhim(List<int> runes, int raIndex) {
    var i = raIndex - 1;
    while (i >= 0 && _isArabicDiacritic(runes[i])) {
      i--;
    }
    if (i < 0) return false;

    for (var j = i + 1; j < raIndex; j++) {
      final cp = runes[j];
      if (cp == 0x064E || cp == 0x064F) return true;
      if (cp == 0x0650) return false;
    }
    return false;
  }

  /// Tags untagged isti'laa letters in plain segments (e.g. ق in حَقُّ).
  static String augmentHeavyLetters(String html) {
    return _mapPlainSegments(html, _wrapHeavyInPlain);
  }

  static String _wrapHeavyInPlain(String segment) {
    if (segment.isEmpty) return segment;

    final runes = segment.runes.toList();
    final out = StringBuffer();

    for (var i = 0; i < runes.length; i++) {
      final ch = String.fromCharCode(runes[i]);
      if (heavyLetters.contains(ch)) {
        final cluster = StringBuffer()..write(ch);
        while (i + 1 < runes.length && _isArabicDiacritic(runes[i + 1])) {
          i++;
          cluster.writeCharCode(runes[i]);
        }
        out.write('<tajweed class=tafkhim>${cluster.toString()}</tajweed>');
      } else {
        out.write(ch);
      }
    }
    return out.toString();
  }

  static int? _firstBaseLetter(String s) {
    for (final cp in s.runes) {
      if (_isBaseLetter(cp)) return cp;
    }
    return null;
  }

  static bool _isBaseLetter(int cp) {
    return (cp >= 0x0621 && cp <= 0x064A) || cp == 0x0671;
  }

  /// Noon/meem ikhfa tag often includes the following consonant; color source only.
  static String _sourceLetterCluster(String content, int sourceLetter) {
    final runes = content.runes.toList();
    var i = 0;
    while (i < runes.length && !_isBaseLetter(runes[i])) {
      i++;
    }
    if (i >= runes.length || runes[i] != sourceLetter) return content;

    final out = StringBuffer()..writeCharCode(runes[i]);
    i++;
    while (i < runes.length && _isArabicDiacritic(runes[i])) {
      out.writeCharCode(runes[i]);
      i++;
    }
    return out.toString();
  }

  /// Tanwin-bearing idgham: plain tanwin source + colored absorbing letter.
  static String? _splitIdghamTanwinForDisplay(String content, String cls) {
    final runes = content.runes.toList();
    int? tanwinIndex;
    for (var i = 0; i < runes.length; i++) {
      if (runes[i] >= 0x064B && runes[i] <= 0x064D) {
        tanwinIndex = i;
        break;
      }
    }
    if (tanwinIndex == null) return null;

    var absorberStart = tanwinIndex + 1;
    while (absorberStart < runes.length && runes[absorberStart] == 0x0020) {
      absorberStart++;
    }
    if (absorberStart >= runes.length || !_isBaseLetter(runes[absorberStart])) {
      return null;
    }

    var absorberEnd = absorberStart + 1;
    while (absorberEnd < runes.length && _isArabicDiacritic(runes[absorberEnd])) {
      absorberEnd++;
    }

    final source = String.fromCharCodes(runes.sublist(0, absorberStart));
    final absorber = String.fromCharCodes(runes.sublist(absorberStart, absorberEnd));
    final tail = String.fromCharCodes(runes.sublist(absorberEnd));
    return '$source<tajweed class=$cls>$absorber</tajweed>$tail';
  }

  static bool _isArabicDiacritic(int codePoint) {
    if (codePoint == 0x0640 || codePoint == 0x0670) return true;
    return codePoint >= 0x064B && codePoint <= 0x0652;
  }
}
