import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final readerSourceProvider = StateProvider<ReaderSource?>((ref) => null);
final targetAyahProvider = StateProvider<int?>((ref) => null);

/// True while [ReaderScreen] is mounted (pushed route or tablet split pane).
final readerScreenVisibleProvider = StateProvider<bool>((ref) => false);

/// True when the surah list and reader share one screen (tablet layout).
final readerSplitLayoutProvider = StateProvider<bool>((ref) => false);

/// Where the user started the current recitation (mini player tap returns here).
enum RecitationReturnSurface { reader, mushaf }

final recitationReturnSurfaceProvider =
    StateProvider<RecitationReturnSurface?>((ref) => null);

/// Scroll the open [ReaderScreen] to a surah/ayah without pushing another route.
class ReaderJumpRequest {
  final int surahId;
  final int ayahNo;
  final int token;

  const ReaderJumpRequest({
    required this.surahId,
    required this.ayahNo,
    required this.token,
  });
}

final readerJumpRequestProvider =
    StateProvider<ReaderJumpRequest?>((ref) => null);

int _readerJumpToken = 0;

void requestReaderJump(
  WidgetRef ref, {
  required int surahId,
  required int ayahNo,
}) {
  _readerJumpToken++;
  ref.read(readerSourceProvider.notifier).state =
      SurahSource(surahId, targetAyahNo: ayahNo);
  ref.read(targetAyahProvider.notifier).state = ayahNo;
  ref.read(readerJumpRequestProvider.notifier).state = ReaderJumpRequest(
    surahId: surahId,
    ayahNo: ayahNo,
    token: _readerJumpToken,
  );
}

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

