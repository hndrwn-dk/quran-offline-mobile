import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';

const mushafPageCount = 604;

class LastReadProgress {
  const LastReadProgress({
    required this.fraction,
    required this.scope,
    required this.current,
    required this.total,
  });

  final double fraction;
  final String scope;
  final int current;
  final int total;

  int get percent => total <= 0 ? 0 : ((current / total) * 100).round().clamp(0, 100);
}

final lastReadProgressProvider = FutureProvider<LastReadProgress?>((ref) async {
  final lastRead = ref.watch(lastReadProvider);
  if (lastRead == null) return null;

  final db = ref.read(databaseProvider);

  switch (lastRead.type) {
    case 'surah':
      final total = await db.getAyahCountForSurah(lastRead.id);
      if (total <= 0) return null;
      final current = (lastRead.ayahNo ?? 1).clamp(1, total);
      return LastReadProgress(
        fraction: current / total,
        scope: 'surah',
        current: current,
        total: total,
      );
    case 'juz':
      final verses = await db.getVersesByJuz(lastRead.id);
      if (verses.isEmpty) return null;
      final total = verses.length;
      var index = 0;
      if (lastRead.ayahNo != null) {
        final targetAyah = lastRead.ayahNo!;
        final targetSurah = lastRead.surahId;
        for (var i = 0; i < verses.length; i++) {
          final verse = verses[i];
          final matchesAyah = verse.ayahNo == targetAyah;
          final matchesSurah = targetSurah == null || verse.surahId == targetSurah;
          if (matchesAyah && matchesSurah) {
            index = i;
            break;
          }
        }
      }
      final current = index + 1;
      return LastReadProgress(
        fraction: current / total,
        scope: 'juz',
        current: current,
        total: total,
      );
    case 'page':
      final page = lastRead.id.clamp(1, mushafPageCount);
      return LastReadProgress(
        fraction: page / mushafPageCount,
        scope: 'page',
        current: page,
        total: mushafPageCount,
      );
    default:
      return null;
  }
});
