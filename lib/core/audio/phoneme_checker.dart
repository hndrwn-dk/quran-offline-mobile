import 'package:quran_offline/core/quran/tajweed_rule_parser.dart';

class PhonemeCheckResult {
  const PhonemeCheckResult({
    required this.laamShamsViolations,
    required this.ghunnahViolations,
    required this.wordScores,
    required this.phonemeTajweedScore,
    required this.possibleMadLazimRush,
  });

  final List<LaamShamsViolation> laamShamsViolations;
  final List<GhunnahViolation> ghunnahViolations;
  final List<WordPhonemeScore> wordScores;
  final int phonemeTajweedScore;
  final bool possibleMadLazimRush;

  bool get hasTajweedIssues =>
      laamShamsViolations.isNotEmpty ||
      ghunnahViolations.isNotEmpty ||
      possibleMadLazimRush;

  bool get isClean =>
      laamShamsViolations.isEmpty &&
      ghunnahViolations.isEmpty &&
      !possibleMadLazimRush &&
      wordScores.every((w) => w.similarity >= 0.85);
}

class LaamShamsViolation {
  const LaamShamsViolation({
    required this.arabicWord,
    required this.expectedToken,
    required this.heardToken,
    required this.tipId,
  });

  final String arabicWord;
  final String expectedToken;
  final String heardToken;
  final String tipId;
}

class GhunnahViolation {
  const GhunnahViolation({
    required this.arabicContext,
    required this.expectedPattern,
    required this.heardPattern,
  });

  final String arabicContext;
  final String expectedPattern;
  final String heardPattern;
}

class WordPhonemeScore {
  const WordPhonemeScore({
    required this.wordIndex,
    required this.arabicWord,
    required this.expectedPhoneme,
    this.heardPhoneme,
    required this.similarity,
  });

  final int wordIndex;
  final String arabicWord;
  final String expectedPhoneme;
  final String? heardPhoneme;
  final double similarity;

  bool get isCorrect => similarity >= 0.85;
  bool get isMispronounced => similarity >= 0.5 && similarity < 0.85;
}

/// Compares STT output to [translitTj] tokens for tajweed coaching hints.
/// Does not replace [SetoranSpeechChecker] verdicts.
class PhonemeChecker {
  PhonemeChecker._();

  static final RegExp _ghunnahPattern = RegExp(r'(nn+|mm+)');
  static final RegExp _alPrefix = RegExp(r'^al(.+)$');

  static PhonemeCheckResult check({
    required String transcript,
    required String? translitTj,
    required String? tajweedHtml,
    required String arabic,
    int? recordingDurationMs,
    String language = 'id',
  }) {
    final tlTj = translitTj?.trim() ?? '';
    if (tlTj.isEmpty || transcript.trim().isEmpty) {
      return _emptyResult();
    }

    final normalizedTranscript = _normalizeTranscript(transcript);
    if (normalizedTranscript.isEmpty) {
      return _emptyResult();
    }

    final expectedTokens = _tokenize(tlTj);
    final heardTokens = _tokenize(normalizedTranscript);
    final tajweedMap = TajweedRuleParser.parse(tajweedHtml);
    final wordScores = _alignAndScore(expectedTokens, heardTokens, arabic);
    final laamViolations = _detectLaamShamsi(
      expectedTokens: expectedTokens,
      heardTokens: heardTokens,
      tajweedMap: tajweedMap,
      arabic: arabic,
      language: language,
    );
    final ghunnahViolations = _detectGhunnah(
      expectedTokens: expectedTokens,
      heardTokens: heardTokens,
      tajweedMap: tajweedMap,
      arabic: arabic,
    );
    final madLazimRush = _checkMadLazimRush(
      tajweedMap: tajweedMap,
      totalWords: expectedTokens.length,
      durationMs: recordingDurationMs,
    );
    final tajweedScore = _computeTajweedScore(
      laamViolations: laamViolations,
      ghunnahViolations: ghunnahViolations,
      madLazimRush: madLazimRush,
      wordScores: wordScores,
    );

    return PhonemeCheckResult(
      laamShamsViolations: laamViolations,
      ghunnahViolations: ghunnahViolations,
      wordScores: wordScores,
      phonemeTajweedScore: tajweedScore,
      possibleMadLazimRush: madLazimRush,
    );
  }

  static PhonemeCheckResult _emptyResult() {
    return const PhonemeCheckResult(
      laamShamsViolations: [],
      ghunnahViolations: [],
      wordScores: [],
      phonemeTajweedScore: 100,
      possibleMadLazimRush: false,
    );
  }

  static String _normalizeTranscript(String raw) {
    var s = raw.toLowerCase().trim();

    if (_isArabicScript(s)) {
      s = _arabicToLatin(s);
    }

    s = s
        .replaceAll(RegExp(r'[āâ]'), 'a')
        .replaceAll(RegExp(r'[īî]'), 'i')
        .replaceAll(RegExp(r'[ūû]'), 'u')
        .replaceAll(RegExp(r'[ḥ]'), 'h')
        .replaceAll(RegExp(r'[ṣ]'), 's')
        .replaceAll(RegExp(r'[ḍ]'), 'd')
        .replaceAll(RegExp(r'[ṭ]'), 't')
        .replaceAll(RegExp(r'[ẓ]'), 'z')
        .replaceAll('ʿ', "'")
        .replaceAll('ʾ', "'");

    s = s.replaceAll(RegExp(r'[-]'), ' ');
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  static bool _isArabicScript(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  static String _arabicToLatin(String arabic) {
    final stripped = arabic.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    const map = {
      'ب': 'b',
      'ت': 't',
      'ث': 'th',
      'ج': 'j',
      'ح': 'h',
      'خ': 'kh',
      'د': 'd',
      'ذ': 'dh',
      'ر': 'r',
      'ز': 'z',
      'س': 's',
      'ش': 'sh',
      'ص': 's',
      'ض': 'd',
      'ط': 't',
      'ظ': 'z',
      'ع': "'",
      'غ': 'gh',
      'ف': 'f',
      'ق': 'q',
      'ك': 'k',
      'ل': 'l',
      'م': 'm',
      'ن': 'n',
      'ه': 'h',
      'و': 'w',
      'ي': 'y',
      'أ': 'a',
      'إ': 'i',
      'آ': 'a',
      'ا': 'a',
      'ى': 'a',
      'ة': 'h',
      'ئ': 'y',
      'ء': "'",
      'ؤ': 'w',
      'ٱ': '',
    };

    return stripped.split('').map((c) => map[c] ?? '').join('');
  }

  static List<String> _tokenize(String s) {
    return s.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  static List<String> _arabicWords(String arabic) {
    return arabic
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static List<WordPhonemeScore> _alignAndScore(
    List<String> expected,
    List<String> heard,
    String arabic,
  ) {
    final arabicWords = _arabicWords(arabic);
    final scores = <WordPhonemeScore>[];
    final usedHeard = List<bool>.filled(heard.length, false);

    for (var i = 0; i < expected.length; i++) {
      final expToken = expected[i];
      String? bestHeardToken;
      var bestSim = 0.0;
      var bestJ = -1;

      final start = (i - 2).clamp(0, heard.length);
      final end = (i + 3).clamp(0, heard.length);

      for (var j = start; j < end; j++) {
        if (usedHeard[j]) continue;
        final sim = _similarity(expToken, heard[j]);
        if (sim > bestSim) {
          bestSim = sim;
          bestHeardToken = heard[j];
          bestJ = j;
        }
      }

      if (bestJ >= 0 && bestSim >= 0.35) {
        usedHeard[bestJ] = true;
      } else {
        bestHeardToken = null;
        bestSim = 0.0;
      }

      scores.add(WordPhonemeScore(
        wordIndex: i,
        arabicWord: i < arabicWords.length ? arabicWords[i] : '',
        expectedPhoneme: expToken,
        heardPhoneme: bestHeardToken,
        similarity: bestSim,
      ));
    }

    return scores;
  }

  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return 1.0 - (dist / maxLen);
  }

  static int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (s[i - 1] == t[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              [
                dp[i - 1][j],
                dp[i][j - 1],
                dp[i - 1][j - 1],
              ].reduce((a, b) => a < b ? a : b);
        }
      }
    }
    return dp[m][n];
  }

  static List<LaamShamsViolation> _detectLaamShamsi({
    required List<String> expectedTokens,
    required List<String> heardTokens,
    required TajweedRuleMap tajweedMap,
    required String arabic,
    required String language,
  }) {
    if (tajweedMap.laamSpans.isEmpty) return [];

    final violations = <LaamShamsViolation>[];
    final arabicWords = _arabicWords(arabic);
    final tip = TajweedSpan(
      arabicText: '',
      rule: TajweedClass.laam_shamsiyah,
      spanIndex: 0,
    ).tipId(language);

    for (var i = 0; i < expectedTokens.length; i++) {
      final exp = expectedTokens[i];
      if (exp.startsWith('al') || exp.startsWith('llahi')) continue;

      final heardWindow = heardTokens
          .skip((i - 1).clamp(0, heardTokens.length))
          .take(3);

      for (final heard in heardWindow) {
        final alMatch = _alPrefix.firstMatch(heard);
        if (alMatch == null) continue;

        final withoutAl = alMatch.group(1)!;
        if (_similarity(withoutAl, exp) < 0.55 &&
            _similarity(withoutAl, _stripLeadingL(exp)) < 0.55) {
          continue;
        }

        violations.add(LaamShamsViolation(
          arabicWord: i < arabicWords.length ? arabicWords[i] : '',
          expectedToken: exp,
          heardToken: heard,
          tipId: tip,
        ));
        break;
      }
    }

    return violations;
  }

  static String _stripLeadingL(String token) {
    if (token.length > 1 && token.startsWith('l')) {
      return token.substring(1);
    }
    return token;
  }

  static List<GhunnahViolation> _detectGhunnah({
    required List<String> expectedTokens,
    required List<String> heardTokens,
    required TajweedRuleMap tajweedMap,
    required String arabic,
  }) {
    if (tajweedMap.ghunnahSpans.isEmpty && !_hasGhunnahToken(expectedTokens)) {
      return [];
    }

    final violations = <GhunnahViolation>[];
    final arabicWords = _arabicWords(arabic);

    for (var i = 0; i < expectedTokens.length; i++) {
      final exp = expectedTokens[i];
      final match = _ghunnahPattern.firstMatch(exp);
      if (match == null) continue;

      final expNormalized =
          exp.replaceAll(RegExp(r'n+'), 'n').replaceAll(RegExp(r'm+'), 'm');

      final heard = i < heardTokens.length ? heardTokens[i] : null;
      if (heard == null) continue;

      if (!_ghunnahPattern.hasMatch(heard) &&
          _similarity(expNormalized, heard) >= 0.55) {
        violations.add(GhunnahViolation(
          arabicContext: i < arabicWords.length ? arabicWords[i] : '',
          expectedPattern: match.group(0)!,
          heardPattern: heard,
        ));
      }
    }

    return violations;
  }

  static bool _hasGhunnahToken(List<String> tokens) {
    return tokens.any((t) => _ghunnahPattern.hasMatch(t));
  }

  static bool _checkMadLazimRush({
    required TajweedRuleMap tajweedMap,
    required int totalWords,
    int? durationMs,
  }) {
    if (durationMs == null || !tajweedMap.hasMadLazim) return false;

    final madLazimCount = tajweedMap.spans
        .where((s) => s.rule == TajweedClass.madda_necessary)
        .length;
    final minExpectedMs = (totalWords * 300) + (madLazimCount * 1200);
    return durationMs < minExpectedMs * 0.6;
  }

  static int _computeTajweedScore({
    required List<LaamShamsViolation> laamViolations,
    required List<GhunnahViolation> ghunnahViolations,
    required bool madLazimRush,
    required List<WordPhonemeScore> wordScores,
  }) {
    var score = 100.0;
    score -= laamViolations.length * 20;
    score -= ghunnahViolations.length * 10;
    if (madLazimRush) score -= 15;

    if (wordScores.isNotEmpty) {
      final avgWordSim = wordScores.map((w) => w.similarity).reduce((a, b) => a + b) /
          wordScores.length;
      if (avgWordSim < 0.7) {
        score -= (0.7 - avgWordSim) * 50;
      }
    }

    return score.clamp(0, 100).round();
  }
}
