import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';

/// Indonesian/English query normaliser (matching only). Version 3.
///
/// Port of tool/id_normalizer.py, spec §6.1.
class IdQueryNormalizer {
  IdQueryNormalizer._();

  static const int normalizerVersion = 3;

  static final _html = RegExp(r'<[^>]+>');
  static final _nonAlnum = RegExp(r'[^\w]+', unicode: true);
  static final _multiSpace = RegExp(r'\s+');
  static final _arabic = RegExp(r'[\u0600-\u06FF]');

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
    'per',
    'ber',
    'ter',
    'pe',
    'be',
    'te',
    'di',
    'ke',
    'se',
  ];
  static const _minStem = 4;
  static const _vowels = {'a', 'i', 'u', 'e', 'o'};
  static const _rootWhitelist = {
    'keluarga',
    'kerja',
    'kertas',
    'kepala',
    'keras',
    'kelas',
    'ketika',
    'kembali',
    'kemudian',
    'kecap',
    'perang',
    'perak',
    'pertama',
    'perlu',
    'percaya',
    'perut',
    'peta',
    'pesan',
    'pekan',
    'pena',
  };

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

  static String _restoreElision(String prefix, String stem) {
    if (stem.isEmpty) return stem;
    if (prefix == 'peny' || prefix == 'meny') {
      if (!stem.startsWith('s')) return 's$stem';
    } else if (prefix == 'peng' || prefix == 'meng') {
      if (stem.startsWith('e') && stem.length > 1) {
        return stem.substring(1);
      }
      if ('aiou'.contains(stem[0]) && !stem.startsWith('k')) {
        return 'k$stem';
      }
    } else if (prefix == 'pem' || prefix == 'mem') {
      if (_vowels.contains(stem[0])) return 'p$stem';
    } else if (prefix == 'pen' || prefix == 'men') {
      if (_vowels.contains(stem[0])) return 't$stem';
    }
    return stem;
  }

  static String? _tryPrefix(String token) {
    if (_rootWhitelist.contains(token)) return token;
    for (final prefix in _prefixes) {
      if (!token.startsWith(prefix)) continue;
      final stem = _restoreElision(prefix, token.substring(prefix.length));
      if (stem.length >= _minStem || _rootWhitelist.contains(stem)) {
        return stem;
      }
      return null;
    }
    return token;
  }

  static String _stripParticle(String token) {
    for (final suffix in ['nya', 'lah', 'kah']) {
      if (token.endsWith(suffix)) {
        final stem = token.substring(0, token.length - suffix.length);
        if (stem.length >= _minStem) return stem;
      }
    }
    return token;
  }

  static String _stemLatin(String token) {
    if (_rootWhitelist.contains(token)) return token;
    token = _stripParticle(token);
    if (_rootWhitelist.contains(token)) return token;
    for (final suffix in ['kan', 'an', 'i']) {
      if (!token.endsWith(suffix)) continue;
      final tentative = token.substring(0, token.length - suffix.length);
      if (tentative.length < _minStem) continue;
      final stemmed = _tryPrefix(tentative);
      if (stemmed == null) continue;
      if (stemmed.length >= _minStem || _rootWhitelist.contains(stemmed)) {
        return stemmed;
      }
    }
    return _tryPrefix(token) ?? token;
  }
}
