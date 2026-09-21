import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';

/// Indonesian/English query normaliser (matching only). Version 1.
///
/// Port of tool/id_normalizer.py, spec §6.1 steps 1–4.
class IdQueryNormalizer {
  IdQueryNormalizer._();

  static const int normalizerVersion = 1;

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

  static String normalize(String text) {
    if (text.isEmpty) return '';
    var s = text.toLowerCase();
    s = s.replaceAll(_html, '');
    s = s.replaceAll(_nonAlnum, ' ');
    s = s.replaceAll(_multiSpace, ' ').trim();
    if (s.isEmpty) return '';

    final tokens = s.split(' ');
    final out = <String>[];
    for (final token in tokens) {
      if (token.isEmpty) continue;
      if (_arabic.hasMatch(token)) {
        out.add(ArabicSearchNormalizer.normalizeForSearch(token));
      } else {
        out.add(_stemLatin(token));
      }
    }
    return out.join(' ');
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
