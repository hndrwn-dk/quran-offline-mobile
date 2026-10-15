import 'package:quran_offline/core/database/database.dart';

class SurahBookmarkGroup {
  const SurahBookmarkGroup({
    required this.surahId,
    required this.items,
  });

  final int surahId;
  final List<Bookmark> items;
}

/// Groups bookmarks by surah.
///
/// [newestFirst] orders groups by the latest bookmark, and ayahs inside a
/// group from newest to oldest. Otherwise groups follow surah number and
/// ayahs follow ayah number.
List<SurahBookmarkGroup> groupBookmarks(
  List<Bookmark> items, {
  required bool newestFirst,
}) {
  final bySurah = <int, List<Bookmark>>{};
  for (final item in items) {
    bySurah.putIfAbsent(item.surahId, () => []).add(item);
  }
  final groups = bySurah.entries.map((entry) {
    final list = [...entry.value];
    if (newestFirst) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      list.sort((a, b) => a.ayahNo.compareTo(b.ayahNo));
    }
    return SurahBookmarkGroup(surahId: entry.key, items: list);
  }).toList();
  if (newestFirst) {
    groups.sort(
      (a, b) => b.items.first.createdAt.compareTo(a.items.first.createdAt),
    );
  } else {
    groups.sort((a, b) => a.surahId.compareTo(b.surahId));
  }
  return groups;
}
