import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/reading/reading_scope.dart';

enum ResumeBoundaryKind { surahEnd, juzEndAyahs, juzEndPages }

/// Closest reading boundary after the resumed position.
class ResumeBoundary {
  const ResumeBoundary({
    required this.remaining,
    required this.kind,
    this.juzNo,
  });

  final int remaining;
  final ResumeBoundaryKind kind;
  final int? juzNo;
}

/// For the verse reader: the closer of the surah end and the juz end, in ayahs.
///
/// Positions already sitting on a boundary are ignored, so the chip never says
/// "0 ayahs left". Returns null when no positive remaining boundary exists.
ResumeBoundary? computeSurahResumeBoundary({
  required List<Verse> surahVerses,
  required int verseIndex,
  required List<Verse> juzVerses,
}) {
  if (surahVerses.isEmpty ||
      verseIndex < 0 ||
      verseIndex >= surahVerses.length) {
    return null;
  }

  final surahRemaining = surahVerses.length - 1 - verseIndex;
  final current = surahVerses[verseIndex];

  final juzIndex = indexOfVerseInJuz(
    juzVerses,
    surahId: current.surahId,
    ayahNo: current.ayahNo,
  );
  final juzRemaining =
      juzIndex == null ? null : juzVerses.length - 1 - juzIndex;

  ResumeBoundary? best;
  if (surahRemaining > 0) {
    best = ResumeBoundary(
      remaining: surahRemaining,
      kind: ResumeBoundaryKind.surahEnd,
    );
  }
  if (juzRemaining != null &&
      juzRemaining > 0 &&
      (best == null || juzRemaining < best.remaining)) {
    best = ResumeBoundary(
      remaining: juzRemaining,
      kind: ResumeBoundaryKind.juzEndAyahs,
      juzNo: current.juz,
    );
  }
  return best;
}

/// For a juz reader: ayahs left until the end of the juz.
ResumeBoundary? computeJuzResumeBoundary({
  required List<Verse> juzVerses,
  required int surahId,
  required int ayahNo,
}) {
  final index = indexOfVerseInJuz(
    juzVerses,
    surahId: surahId,
    ayahNo: ayahNo,
  );
  if (index == null) return null;
  final remaining = juzVerses.length - 1 - index;
  if (remaining <= 0) return null;
  return ResumeBoundary(
    remaining: remaining,
    kind: ResumeBoundaryKind.juzEndAyahs,
    juzNo: juzVerses.first.juz,
  );
}

/// For the mushaf: pages left until the last page of the current juz.
ResumeBoundary? computePageResumeBoundary({
  required int pageNo,
  required List<Verse> juzVerses,
}) {
  if (juzVerses.isEmpty) return null;

  final range = JuzPageRange.fromVerses(juzVerses);
  if (range == null) return null;
  final remaining = range.endPage - pageNo;
  if (remaining <= 0) return null;

  return ResumeBoundary(
    remaining: remaining,
    kind: ResumeBoundaryKind.juzEndPages,
    juzNo: juzVerses.first.juz,
  );
}
