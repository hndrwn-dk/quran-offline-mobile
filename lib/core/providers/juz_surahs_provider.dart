import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';

class JuzSurahsInfo {
  final int juzNo;
  final List<int> surahIds;
  final Map<int, int> surahAyahCounts;

  JuzSurahsInfo({
    required this.juzNo,
    required this.surahIds,
    required this.surahAyahCounts,
  });
}

final juzSurahsProvider = FutureProvider.family<JuzSurahsInfo, int>((ref, juzNo) async {
  final db = ref.read(databaseProvider);
  final verses = await db.getVersesByJuz(juzNo);
  final surahIds = <int>[];
  final surahAyahCounts = <int, int>{};

  for (final verse in verses) {
    surahAyahCounts[verse.surahId] = (surahAyahCounts[verse.surahId] ?? 0) + 1;
    if (surahIds.isEmpty || surahIds.last != verse.surahId) {
      surahIds.add(verse.surahId);
    }
  }

  return JuzSurahsInfo(
    juzNo: juzNo,
    surahIds: surahIds,
    surahAyahCounts: surahAyahCounts,
  );
});

