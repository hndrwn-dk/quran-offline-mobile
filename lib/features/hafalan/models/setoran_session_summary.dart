import 'package:quran_offline/core/audio/phoneme_checker.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/quran/tajweed_rule_parser.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/hafalan/models/setoran_ayah_fade_state.dart';

class TajwidSummaryNote {
  const TajwidSummaryNote({
    required this.ayahNo,
    required this.ruleLabel,
    required this.detail,
    required this.isMajor,
  });

  final int ayahNo;
  final String ruleLabel;
  final String detail;
  final bool isMajor;
}

class SetoranSessionSummary {
  const SetoranSessionSummary({
    required this.totalAyahs,
    required this.revealedCount,
    required this.errorCount,
    required this.ghostCount,
    required this.avgTajwidScore,
    required this.avgTextScore,
    required this.topTajwidNotes,
    required this.reviewAyahIndices,
  });

  final int totalAyahs;
  final int revealedCount;
  final int errorCount;
  final int ghostCount;
  final int? avgTajwidScore;
  final int? avgTextScore;
  final List<TajwidSummaryNote> topTajwidNotes;
  final List<int> reviewAyahIndices;

  bool get allRevealed => revealedCount == totalAyahs && totalAyahs > 0;
  bool get needsImprovement =>
      errorCount > 0 ||
      reviewAyahIndices.isNotEmpty ||
      (avgTajwidScore != null && avgTajwidScore! < 80);
}

class SetoranSessionSummaryBuilder {
  SetoranSessionSummaryBuilder._();

  static SetoranSessionSummary build({
    required List<Verse> verses,
    required List<SetoranAyahFadeState> states,
    required Map<int, PhonemeCheckResult> phonemeByAyah,
    required Map<int, double> speechScoreByAyah,
    required String lang,
  }) {
    var revealed = 0;
    var errors = 0;
    var ghost = 0;
    final reviewIndices = <int>[];
    final notes = <TajwidSummaryNote>[];
    final tajwidScores = <int>[];
    final textScores = <double>[];

    for (var i = 0; i < verses.length; i++) {
      final st = i < states.length ? states[i] : SetoranAyahFadeState.ghost;
      switch (st) {
        case SetoranAyahFadeState.revealed:
          revealed++;
        case SetoranAyahFadeState.error:
          errors++;
          reviewIndices.add(i);
        case SetoranAyahFadeState.ghost:
          ghost++;
      }

      final phoneme = phonemeByAyah[i];
      if (phoneme != null) {
        tajwidScores.add(phoneme.phonemeTajweedScore);
        if (st == SetoranAyahFadeState.revealed &&
            (phoneme.hasTajweedIssues || phoneme.phonemeTajweedScore < 80)) {
          if (!reviewIndices.contains(i)) {
            reviewIndices.add(i);
          }
        }
        notes.addAll(_notesFromPhoneme(
          ayahNo: verses[i].ayahNo,
          phoneme: phoneme,
          lang: lang,
        ));
      }

      final textScore = speechScoreByAyah[i];
      if (textScore != null) {
        textScores.add(textScore);
      }
    }

    reviewIndices.sort();
    notes.sort((a, b) {
      if (a.isMajor != b.isMajor) return a.isMajor ? -1 : 1;
      return a.ayahNo.compareTo(b.ayahNo);
    });

    return SetoranSessionSummary(
      totalAyahs: verses.length,
      revealedCount: revealed,
      errorCount: errors,
      ghostCount: ghost,
      avgTajwidScore: _averageInt(tajwidScores),
      avgTextScore: _averagePercent(textScores),
      topTajwidNotes: notes.take(3).toList(),
      reviewAyahIndices: reviewIndices,
    );
  }

  static List<TajwidSummaryNote> _notesFromPhoneme({
    required int ayahNo,
    required PhonemeCheckResult phoneme,
    required String lang,
  }) {
    final out = <TajwidSummaryNote>[];

    for (final v in phoneme.laamShamsViolations) {
      out.add(TajwidSummaryNote(
        ayahNo: ayahNo,
        ruleLabel: AppLocalizations.getSetoranTajwidLaamShams(lang),
        detail: '${v.expectedToken} -> ${v.heardToken}',
        isMajor: true,
      ));
    }
    for (final v in phoneme.ghunnahViolations) {
      out.add(TajwidSummaryNote(
        ayahNo: ayahNo,
        ruleLabel: AppLocalizations.getSetoranTajwidGhunnah(lang),
        detail: '${v.expectedPattern} -> ${v.heardPattern}',
        isMajor: false,
      ));
    }
    if (phoneme.possibleMadLazimRush) {
      out.add(TajwidSummaryNote(
        ayahNo: ayahNo,
        ruleLabel: TajweedSpan(
          arabicText: '',
          rule: TajweedClass.madda_necessary,
          spanIndex: 0,
        ).labelId(lang),
        detail: AppLocalizations.getSetoranTajwidMadLazimRush(lang),
        isMajor: false,
      ));
    }

    return out;
  }

  static int? _averageInt(List<int> values) {
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return (sum / values.length).round();
  }

  static int? _averagePercent(List<double> values) {
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return (sum / values.length * 100).round();
  }
}

enum SetoranSummaryResult {
  cancelled,
  retryAyah,
  markedDone,
}
