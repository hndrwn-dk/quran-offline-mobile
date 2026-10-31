import 'package:quran_offline/core/database/database.dart';

/// Index of a specific verse inside the verses of a juz.
///
/// Shared by the Continue card and the resume hint so both count the same way.
int? indexOfVerseInJuz(
  List<Verse> juzVerses, {
  required int surahId,
  required int ayahNo,
}) {
  for (var i = 0; i < juzVerses.length; i++) {
    final verse = juzVerses[i];
    if (verse.surahId == surahId && verse.ayahNo == ayahNo) return i;
  }
  return null;
}

/// Page span covered by a juz.
class JuzPageRange {
  const JuzPageRange({required this.startPage, required this.endPage});

  final int startPage;
  final int endPage;

  int get totalPages => endPage - startPage + 1;

  /// 1-based progress of [pageNo] inside this juz.
  double progressForPage(int pageNo) {
    final current = (pageNo - startPage + 1).clamp(1, totalPages);
    return current / totalPages;
  }

  static JuzPageRange? tryCreate(int? startPage, int? endPage) {
    if (startPage == null || endPage == null || endPage < startPage) {
      return null;
    }
    return JuzPageRange(startPage: startPage, endPage: endPage);
  }

  static JuzPageRange? fromVerses(List<Verse> verses) {
    if (verses.isEmpty) return null;
    var start = verses.first.page;
    var end = start;
    for (final verse in verses) {
      if (verse.page < start) start = verse.page;
      if (verse.page > end) end = verse.page;
    }
    return JuzPageRange(startPage: start, endPage: end);
  }
}
