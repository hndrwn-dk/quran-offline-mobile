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
  final surahIds = await db.getSurahIdsInJuz(juzNo);
  final surahAyahCounts = <int, int>{};
  
  for (final surahId in surahIds) {
    final ayahCount = await db.getAyahCountForSurah(surahId);
    surahAyahCounts[surahId] = ayahCount;
  }
  
  return JuzSurahsInfo(
    juzNo: juzNo,
    surahIds: surahIds,
    surahAyahCounts: surahAyahCounts,
  );
});

