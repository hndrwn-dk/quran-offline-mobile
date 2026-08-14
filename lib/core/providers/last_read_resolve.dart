import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';

/// Index of [ayahNo] in [verses].
///
/// When [requireSurahId] is true (juz resume), both surah and ayah must match
/// and a missing [surahId] does not fall back to the first matching ayah number.
int? indexOfTargetVerse(
  List<Verse> verses, {
  required int ayahNo,
  int? surahId,
  bool requireSurahId = false,
}) {
  if (requireSurahId && surahId == null) return null;
  for (var i = 0; i < verses.length; i++) {
    final verse = verses[i];
    if (verse.ayahNo != ayahNo) continue;
    if (surahId != null && verse.surahId != surahId) continue;
    return i;
  }
  return null;
}

/// Juz widget/progress coordinates. Legacy rows without [LastReadPosition.surahId]
/// resolve to the first verse of the juz instead of an ayah-only match.
({int surahId, int ayahNo})? resolveJuzSurahAyah(
  List<Verse> verses,
  LastReadPosition lastRead,
) {
  if (verses.isEmpty) return null;
  if (lastRead.ayahNo != null) {
    final index = indexOfTargetVerse(
      verses,
      ayahNo: lastRead.ayahNo!,
      surahId: lastRead.surahId,
      requireSurahId: true,
    );
    if (index != null) {
      final verse = verses[index];
      return (surahId: verse.surahId, ayahNo: verse.ayahNo);
    }
  }
  final first = verses.first;
  return (surahId: first.surahId, ayahNo: first.ayahNo);
}

bool lastReadCardHandlesType(String type) {
  return switch (type) {
    'surah' || 'juz' || 'page' || 'surah_in_juz' => true,
    _ => false,
  };
}
