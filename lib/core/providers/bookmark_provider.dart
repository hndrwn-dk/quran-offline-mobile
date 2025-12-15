import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';

final bookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getAllBookmarks();
});

final bookmarkRefreshProvider = StateProvider<int>((ref) => 0);

Future<void> toggleBookmark(WidgetRef ref, int surahId, int ayahNo) async {
  final db = ref.read(databaseProvider);
  await db.toggleBookmark(surahId, ayahNo);
  ref.read(bookmarkRefreshProvider.notifier).state++;
  ref.invalidate(bookmarksProvider);
}

Future<void> deleteBookmarksBulk(WidgetRef ref, List<Bookmark> items) async {
  final db = ref.read(databaseProvider);
  await db.deleteBookmarks(items);
  ref.read(bookmarkRefreshProvider.notifier).state++;
  ref.invalidate(bookmarksProvider);
}

Future<void> deleteAllBookmarks(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  await db.deleteAllBookmarks();
  ref.read(bookmarkRefreshProvider.notifier).state++;
  ref.invalidate(bookmarksProvider);
}

Future<bool> isBookmarked(WidgetRef ref, int surahId, int ayahNo) async {
  final db = ref.read(databaseProvider);
  final bookmark = await db.getBookmark(surahId, ayahNo);
  return bookmark != null;
}

