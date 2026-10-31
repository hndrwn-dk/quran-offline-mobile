import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/last_read_resolve.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/reading/reading_scope.dart';

/// Where the user stopped, resolved for the Continue card.
class LastReadLocation {
  const LastReadLocation({
    required this.type,
    this.surahId,
    this.ayahNo,
    this.pageNo,
    this.juzNo,
    this.juzStartPage,
    this.juzEndPage,
  });

  final String type;
  final int? surahId;
  final int? ayahNo;
  final int? pageNo;
  final int? juzNo;
  final int? juzStartPage;
  final int? juzEndPage;
}

/// Fraction of the juz already read, based on its page range.
double? pageProgressInJuz({
  required int pageNo,
  int? startPage,
  int? endPage,
}) {
  final range = JuzPageRange.tryCreate(startPage, endPage);
  return range?.progressForPage(pageNo);
}

/// Continue-card location, resolved locally from the last-read position.
final lastReadLocationProvider = FutureProvider<LastReadLocation?>((ref) async {
  final lastRead = ref.watch(lastReadProvider);
  if (lastRead == null) return null;

  final db = ref.read(databaseProvider);
  switch (lastRead.type) {
    case 'surah':
      final verse = await db.getVerse(lastRead.id, lastRead.ayahNo ?? 1);
      return LastReadLocation(
        type: lastRead.type,
        surahId: lastRead.id,
        ayahNo: lastRead.ayahNo,
        juzNo: verse?.juz,
      );
    case 'surah_in_juz':
      return LastReadLocation(
        type: lastRead.type,
        surahId: lastRead.id,
        ayahNo: lastRead.ayahNo,
        juzNo: lastRead.surahId,
      );
    case 'juz':
      final verses = await db.getVersesByJuz(lastRead.id);
      final coords = resolveJuzSurahAyah(verses, lastRead);
      if (coords == null) return null;
      return LastReadLocation(
        type: lastRead.type,
        surahId: coords.surahId,
        ayahNo: coords.ayahNo,
        juzNo: lastRead.id,
      );
    case 'page':
      final pageVerses = await db.getVersesByPage(lastRead.id);
      final juzNo = pageVerses.isEmpty ? null : pageVerses.first.juz;
      final range = juzNo == null
          ? null
          : JuzPageRange.fromVerses(await db.getVersesByJuz(juzNo));
      return LastReadLocation(
        type: lastRead.type,
        surahId: lastRead.surahId ??
            (pageVerses.isEmpty ? null : pageVerses.first.surahId),
        ayahNo: lastRead.ayahNo,
        pageNo: lastRead.id,
        juzNo: juzNo,
        juzStartPage: range?.startPage,
        juzEndPage: range?.endPage,
      );
    default:
      return null;
  }
});
