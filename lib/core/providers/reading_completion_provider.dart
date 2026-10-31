import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/reading/reading_completion.dart';

/// Resolves whether the stored last-read is the end of its unit, and where to
/// continue next. Null while the unit is not complete.
final readingCompletionProvider =
    FutureProvider<ReadingCompletion?>((ref) async {
  final lastRead = ref.watch(lastReadProvider);
  if (lastRead == null) return null;

  switch (lastRead.type) {
    case 'surah':
    case 'surah_in_juz':
      final progress = await ref.watch(lastReadProgressProvider.future);
      return resolveSurahCompletion(lastRead: lastRead, progress: progress);

    case 'juz':
      final progress = await ref.watch(lastReadProgressProvider.future);
      if (progress == null ||
          progress.total <= 0 ||
          progress.current < progress.total) {
        return null;
      }
      final juzNo = lastRead.id;
      if (juzNo >= 30) {
        return resolveJuzCompletion(
          lastRead: lastRead,
          progress: progress,
          nextJuzFirstVerse: null,
        );
      }
      final db = ref.read(databaseProvider);
      final nextVerses = await db.getVersesByJuz(juzNo + 1);
      return resolveJuzCompletion(
        lastRead: lastRead,
        progress: progress,
        nextJuzFirstVerse: nextVerses.isEmpty ? null : nextVerses.first,
      );

    case 'page':
      final location = await ref.watch(lastReadLocationProvider.future);
      return resolvePageCompletion(lastRead: lastRead, location: location);

    default:
      return null;
  }
});
