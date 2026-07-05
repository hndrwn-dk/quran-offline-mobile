import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';

/// Dual-layer reading progress for the home screen widget (surah + juz).
class WidgetReadingProgress {
  const WidgetReadingProgress({
    required this.surahId,
    required this.ayahNo,
    required this.surahName,
    required this.surahCurrent,
    required this.surahTotal,
    required this.surahPercent,
    required this.juzNo,
    required this.juzCurrent,
    required this.juzTotal,
    required this.juzPercent,
  });

  final int surahId;
  final int ayahNo;
  final String surahName;
  final int surahCurrent;
  final int surahTotal;
  final int surahPercent;
  final int juzNo;
  final int juzCurrent;
  final int juzTotal;
  final int juzPercent;
}

int widgetProgressPercent(int current, int total) {
  if (total <= 0) return 0;
  return ((current / total) * 100).round().clamp(0, 100);
}

/// Resolves surah + ayah coordinates from any [LastReadPosition] type.
Future<({int surahId, int ayahNo})?> resolveSurahAyahFromLastRead(
  AppDatabase db,
  LastReadPosition lastRead,
) async {
  switch (lastRead.type) {
    case 'surah':
      return (
        surahId: lastRead.id,
        ayahNo: (lastRead.ayahNo ?? 1).clamp(1, 999),
      );
    case 'surah_in_juz':
      return (
        surahId: lastRead.id,
        ayahNo: (lastRead.ayahNo ?? 1).clamp(1, 999),
      );
    case 'page':
      final surahId = lastRead.surahId;
      if (surahId == null) return null;
      return (
        surahId: surahId,
        ayahNo: (lastRead.ayahNo ?? 1).clamp(1, 999),
      );
    case 'juz':
      final verses = await db.getVersesByJuz(lastRead.id);
      if (verses.isEmpty) return null;
      if (lastRead.ayahNo != null) {
        final targetAyah = lastRead.ayahNo!;
        final targetSurah = lastRead.surahId;
        for (final verse in verses) {
          final matchesAyah = verse.ayahNo == targetAyah;
          final matchesSurah =
              targetSurah == null || verse.surahId == targetSurah;
          if (matchesAyah && matchesSurah) {
            return (surahId: verse.surahId, ayahNo: verse.ayahNo);
          }
        }
      }
      final first = verses.first;
      return (surahId: first.surahId, ayahNo: first.ayahNo);
    default:
      return null;
  }
}

/// Computes surah + juz progress bars from last-read position.
Future<WidgetReadingProgress?> computeWidgetReadingProgress({
  required AppDatabase db,
  required LastReadPosition lastRead,
  required String surahDisplayName,
}) async {
  final coords = await resolveSurahAyahFromLastRead(db, lastRead);
  if (coords == null) return null;

  final surahTotal = await db.getAyahCountForSurah(coords.surahId);
  if (surahTotal <= 0) return null;

  final surahCurrent = coords.ayahNo.clamp(1, surahTotal);
  final verse = await db.getVerse(coords.surahId, surahCurrent);
  final juzNo = verse?.juz;
  if (juzNo == null || juzNo <= 0) return null;

  final juzVerses = await db.getVersesByJuz(juzNo);
  if (juzVerses.isEmpty) return null;

  var juzIndex = 0;
  for (var i = 0; i < juzVerses.length; i++) {
    final v = juzVerses[i];
    if (v.surahId == coords.surahId && v.ayahNo == surahCurrent) {
      juzIndex = i;
      break;
    }
  }

  final juzCurrent = juzIndex + 1;
  final juzTotal = juzVerses.length;

  return WidgetReadingProgress(
    surahId: coords.surahId,
    ayahNo: surahCurrent,
    surahName: surahDisplayName,
    surahCurrent: surahCurrent,
    surahTotal: surahTotal,
    surahPercent: widgetProgressPercent(surahCurrent, surahTotal),
    juzNo: juzNo,
    juzCurrent: juzCurrent,
    juzTotal: juzTotal,
    juzPercent: widgetProgressPercent(juzCurrent, juzTotal),
  );
}
