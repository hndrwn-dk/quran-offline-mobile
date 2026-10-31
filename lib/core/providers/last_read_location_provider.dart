import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/last_read_resolve.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';

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
  if (startPage == null || endPage == null || endPage < startPage) return null;
  final total = endPage - startPage + 1;
  if (total <= 0) return null;
  final current = (pageNo - startPage + 1).clamp(1, total);
  return current / total;
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
      int? startPage;
      int? endPage;
      if (juzNo != null) {
        final juzVerses = await db.getVersesByJuz(juzNo);
        if (juzVerses.isNotEmpty) {
          startPage = juzVerses.first.page;
          endPage = juzVerses.first.page;
          for (final verse in juzVerses) {
            if (verse.page < startPage!) startPage = verse.page;
            if (verse.page > endPage!) endPage = verse.page;
          }
        }
      }
      return LastReadLocation(
        type: lastRead.type,
        surahId: lastRead.surahId ??
            (pageVerses.isEmpty ? null : pageVerses.first.surahId),
        ayahNo: lastRead.ayahNo,
        pageNo: lastRead.id,
        juzNo: juzNo,
        juzStartPage: startPage,
        juzEndPage: endPage,
      );
    default:
      return null;
  }
});
