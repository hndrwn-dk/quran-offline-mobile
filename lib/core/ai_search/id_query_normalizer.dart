import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';

/// Indonesian/English query normaliser (matching only). Version 2.
///
/// Port of tool/id_normalizer.py, spec §6.1.
class IdQueryNormalizer {
  IdQueryNormalizer._();

  static const int normalizerVersion = 2;

  static final _html = RegExp(r'<[^>]+>');
  static final _nonAlnum = RegExp(r'[^\w]+', unicode: true);
  static final _multiSpace = RegExp(r'\s+');
  static final _arabic = RegExp(r'[\u0600-\u06FF]');

  static const _suffixesInflect = ['nya', 'lah', 'kah'];
  static const _prefixes = [
    'meng',
    'meny',
    'mem',
    'men',
    'me',
    'peng',
    'peny',
    'pem',
    'pen',
    'pe',
    'ber',
    'ter',
    'di',
    'ke',
    'se',
  ];
  static const _suffixesDeriv = ['kan', 'an', 'i'];
  static const _minStem = 3;

  static const _stopwords = {
    'untuk',
    'yang',
    'dan',
    'di',
    'ke',
    'dari',
    'dengan',
    'kepada',
    'pada',
    'saat',
    'ketika',
    'agar',
    'supaya',
    'bagi',
    'itu',
    'ini',
    'ada',
    'atau',
    'juga',
    'akan',
    'sudah',
    'telah',
    'oleh',
    'dalam',
    'the',
    'a',
    'an',
    'of',
    'for',
    'to',
    'in',
    'on',
    'and',
    'or',
    'with',
    'when',
    'is',
    'are',
  };

  static bool _isStopword(String original, String stemmed) {
    return _stopwords.contains(original) || _stopwords.contains(stemmed);
  }

  static String normalize(String text) {
    if (text.isEmpty) return '';
    var s = text.toLowerCase();
    s = s.replaceAll(_html, '');
    s = s.replaceAll(_nonAlnum, ' ');
    s = s.replaceAll(_multiSpace, ' ').trim();
    if (s.isEmpty) return '';

    final originals = <String>[];
    final kept = <String>[];
    var allStop = true;
    for (final token in s.split(' ')) {
      if (token.isEmpty) continue;
      originals.add(token);
      if (_arabic.hasMatch(token)) {
        kept.add(ArabicSearchNormalizer.normalizeForSearch(token));
        allStop = false;
      } else {
        final stemmed = _stemLatin(token);
        if (_isStopword(token, stemmed)) {
          continue;
        }
        kept.add(stemmed);
        allStop = false;
      }
    }
    if (originals.isEmpty) return '';
    if (allStop) return originals.join(' ');
    return kept.join(' ');
  }

  static String _stemLatin(String token) {
    var t = _stripOneSuffix(token, _suffixesInflect);
    t = _stripOnePrefix(t);
    t = _stripOneSuffix(t, _suffixesDeriv);
    return t;
  }

  static String _stripOneSuffix(String token, List<String> suffixes) {
    for (final suffix in suffixes) {
      if (token.endsWith(suffix)) {
        final stem = token.substring(0, token.length - suffix.length);
        final minLen = suffix == 'kan' ? 4 : _minStem;
        if (stem.length >= minLen) return stem;
        return token;
      }
    }
    return token;
  }

  static String _stripOnePrefix(String token) {
    for (final prefix in _prefixes) {
      if (token.startsWith(prefix)) {
        final stem = token.substring(prefix.length);
        if (stem.length >= _minStem) return stem;
      }
    }
    return token;
  }
}
