import 'package:quran_offline/core/audio/setoran_speech_recognizer.dart';
import 'package:quran_offline/core/database/database.dart';

enum SetoranSpeechVerdict {
  correct,
  incorrect,
  uncertain,
}

class SetoranSpeechCheckResult {
  const SetoranSpeechCheckResult({
    required this.verdict,
    required this.score,
    required this.transcript,
  });

  final SetoranSpeechVerdict verdict;
  final double score;
  final String transcript;
}

/// Compares device speech recognition output to the expected ayah text.
class SetoranSpeechChecker {
  SetoranSpeechChecker._();

  static const double correctThreshold = 0.72;
  static const double minimumTranscriptLength = 2;

  static SetoranSpeechCheckResult check({
    required String transcript,
    required Verse verse,
  }) {
    final trimmed = transcript.trim();
    if (trimmed.length < minimumTranscriptLength) {
      return SetoranSpeechCheckResult(
        verdict: SetoranSpeechVerdict.uncertain,
        score: 0,
        transcript: trimmed,
      );
    }

    if (setoranTranscriptLooksLatin(trimmed)) {
      return SetoranSpeechCheckResult(
        verdict: SetoranSpeechVerdict.uncertain,
        score: 0,
        transcript: trimmed,
      );
    }

    final normalizedTranscript = _normalizeForMatch(trimmed);
    final references = _referenceForms(verse);
    var best = 0.0;
    for (final ref in references) {
      if (ref.isEmpty) continue;
      final score = _scorePair(normalizedTranscript, ref);
      if (score > best) best = score;
    }

    final verdict = best >= correctThreshold
        ? SetoranSpeechVerdict.correct
        : SetoranSpeechVerdict.incorrect;

    return SetoranSpeechCheckResult(
      verdict: verdict,
      score: best,
      transcript: trimmed,
    );
  }

  static List<String> _referenceForms(Verse verse) {
    final forms = <String>{
      _normalizeArabic(verse.arabic),
      _normalizeLatin(verse.translitTj ?? ''),
      _normalizeLatin(verse.translit ?? ''),
    };
    forms.removeWhere((s) => s.length < minimumTranscriptLength);
    return forms.toList();
  }

  static String _normalizeForMatch(String input) {
    if (_looksArabic(input)) {
      return _normalizeArabic(input);
    }
    return _normalizeLatin(input);
  }

  static bool _looksArabic(String input) {
    for (final codeUnit in input.runes) {
      if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) return true;
    }
    return false;
  }

  static String _normalizeArabic(String input) {
    var s = input;
    final tashkeel = RegExp(
      r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
    );
    s = s.replaceAll(tashkeel, '');
    s = s.replaceAll(RegExp(r'[\u0640\u200F\u200E]'), '');
    s = s.replaceAll(RegExp(r'[^\u0621-\u064A\s]'), ' ');
    const map = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ٱ': 'ا',
      'ء': '',
      'ؤ': 'و',
      'ئ': 'ي',
      'ة': 'ه',
      'ى': 'ي',
      'ﻻ': 'لا',
      'لا': 'لا',
    };
    for (final entry in map.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.replaceAll(' ', '');
  }

  static String _normalizeLatin(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r"['ʿ`´]"), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    s = s.replaceAll(RegExp(r'\bn{2,}\b'), 'n');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.replaceAll(' ', '');
  }

  static double _scorePair(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;

    final ratio = _levenshteinRatio(a, b);
    final containsBoost = a.contains(b) || b.contains(a) ? 0.12 : 0.0;
    final prefixBoost = a.startsWith(b) || b.startsWith(a) ? 0.08 : 0.0;
    return (ratio + containsBoost + prefixBoost).clamp(0.0, 1.0);
  }

  static double _levenshteinRatio(String a, String b) {
    final distance = _levenshteinDistance(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1;
    return 1 - (distance / maxLen);
  }

  static int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        curr[j + 1] = _min3(
          curr[j] + 1,
          prev[j + 1] + 1,
          prev[j] + cost,
        );
      }
      for (var j = 0; j < prev.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  static int _min3(int a, int b, int c) {
    var m = a;
    if (b < m) m = b;
    if (c < m) m = c;
    return m;
  }
}
