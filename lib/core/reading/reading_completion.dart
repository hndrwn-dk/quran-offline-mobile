import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';

/// A finished unit and where reading should continue next.
class ReadingCompletion {
  const ReadingCompletion({
    required this.kind,
    required this.khatam,
    this.finishedSurahId,
    this.finishedJuzNo,
    this.nextSurahId,
    this.nextAyahNo,
    this.nextJuzNo,
    this.nextPageNo,
  });

  /// 'surah', 'juz', or 'page' — the unit that was completed.
  final String kind;
  final bool khatam;
  final int? finishedSurahId;
  final int? finishedJuzNo;
  final int? nextSurahId;
  final int? nextAyahNo;
  final int? nextJuzNo;
  final int? nextPageNo;
}

/// True when the surah reader is on the final ayah of the surah.
ReadingCompletion? resolveSurahCompletion({
  required LastReadPosition lastRead,
  required LastReadProgress? progress,
}) {
  if (progress == null || progress.total <= 0) return null;
  if (progress.current < progress.total) return null;

  final surahId = lastRead.id;
  if (surahId >= 114) {
    return ReadingCompletion(
      kind: 'surah',
      khatam: true,
      finishedSurahId: surahId,
      nextSurahId: 1,
      nextAyahNo: 1,
    );
  }
  return ReadingCompletion(
    kind: 'surah',
    khatam: false,
    finishedSurahId: surahId,
    nextSurahId: surahId + 1,
    nextAyahNo: 1,
  );
}

/// True when the juz reader is on the last verse of the juz.
///
/// [nextJuzFirstVerse] is the first verse of the following juz; pass null only
/// for Juz 30, where the completion is khatam.
ReadingCompletion? resolveJuzCompletion({
  required LastReadPosition lastRead,
  required LastReadProgress? progress,
  required Verse? nextJuzFirstVerse,
}) {
  if (progress == null || progress.total <= 0) return null;
  if (progress.current < progress.total) return null;

  final juzNo = lastRead.id;
  if (juzNo >= 30) {
    return ReadingCompletion(
      kind: 'juz',
      khatam: true,
      finishedJuzNo: juzNo,
      nextSurahId: 1,
      nextAyahNo: 1,
    );
  }
  if (nextJuzFirstVerse == null) return null;

  return ReadingCompletion(
    kind: 'juz',
    khatam: false,
    finishedJuzNo: juzNo,
    nextJuzNo: juzNo + 1,
    nextSurahId: nextJuzFirstVerse.surahId,
    nextAyahNo: nextJuzFirstVerse.ayahNo,
  );
}

/// True when the mushaf page is the last page of its juz.
ReadingCompletion? resolvePageCompletion({
  required LastReadPosition lastRead,
  required LastReadLocation? location,
}) {
  final endPage = location?.juzEndPage;
  if (endPage == null || endPage != lastRead.id) return null;

  final pageNo = lastRead.id;
  final khatam = pageNo >= 604;
  return ReadingCompletion(
    kind: 'page',
    khatam: khatam,
    finishedJuzNo: location?.juzNo,
    nextPageNo: khatam ? 1 : pageNo + 1,
  );
}

/// Concrete place to open for a completed unit.
class NextReadTarget {
  const NextReadTarget({
    this.source,
    this.targetSurahId,
    this.targetAyahNo,
    this.pageNo,
  });

  final ReaderSource? source;
  final int? targetSurahId;
  final int? targetAyahNo;
  final int? pageNo;
}

NextReadTarget nextReadTarget(ReadingCompletion completion) {
  if (completion.kind == 'page') {
    return NextReadTarget(pageNo: completion.nextPageNo ?? 1);
  }
  if (completion.nextJuzNo != null) {
    return NextReadTarget(
      source: JuzSource(completion.nextJuzNo!),
      targetSurahId: completion.nextSurahId,
      targetAyahNo: completion.nextAyahNo,
    );
  }
  return NextReadTarget(
    source: SurahSource(
      completion.nextSurahId ?? 1,
      targetAyahNo: completion.nextAyahNo ?? 1,
    ),
    targetAyahNo: completion.nextAyahNo ?? 1,
  );
}
