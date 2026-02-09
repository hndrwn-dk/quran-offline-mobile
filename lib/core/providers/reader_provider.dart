import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final readerSourceProvider = StateProvider<ReaderSource?>((ref) => null);
final targetAyahProvider = StateProvider<int?>((ref) => null);

final readerVersesProvider = FutureProvider.family<List<Verse>, ReaderSource>((ref, source) async {
  final db = ref.read(databaseProvider);

  switch (source) {
    case SurahSource(:final surahId):
      return await db.getVersesBySurah(surahId);
    case JuzSource(:final juzNo):
      return await db.getVersesByJuz(juzNo);
    case PageSource(:final pageNo):
      return await db.getVersesByPage(pageNo);
    case SurahInJuzSource(:final juzNo, :final surahId):
      return await db.getVersesBySurahInJuz(surahId, juzNo);
  }
});

