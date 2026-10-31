import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';

/// True when [verseIndex] is the last ayah of the surah being read.
///
/// Only a plain surah reader counts: juz and page reads do not complete a
/// surah, and [SurahInJuzSource] ends at the juz boundary, not the surah.
bool isSurahCompletion(
  ReaderSource source,
  List<Verse> verses,
  int verseIndex,
) {
  if (source is! SurahSource) return false;
  if (verses.isEmpty) return false;
  if (verseIndex != verses.length - 1) return false;
  return verses.last.surahId == source.surahId;
}

/// True when [pageNo] is the highest page containing a verse of its juz.
///
/// A juz can end mid-page, so this compares against the last page of the
/// juz's verses rather than a fixed page number.
bool isLastPageOfJuz({
  required int pageNo,
  required List<Verse> pageVerses,
  required List<Verse> juzVerses,
}) {
  if (pageVerses.isEmpty || juzVerses.isEmpty) return false;

  var lastPage = 0;
  for (final verse in juzVerses) {
    if (verse.page > lastPage) lastPage = verse.page;
  }
  return lastPage > 0 && pageNo == lastPage;
}
