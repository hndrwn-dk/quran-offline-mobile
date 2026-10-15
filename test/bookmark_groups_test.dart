import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/features/library/bookmark_groups.dart';

Bookmark _mark(int surah, int ayah, DateTime created) {
  return Bookmark(
    surahId: surah,
    ayahNo: ayah,
    createdAt: created,
    openContext: 'surah',
  );
}

void main() {
  test('newest groups follow the latest bookmark, items newest first', () {
    final groups = groupBookmarks(
      [
        _mark(112, 4, DateTime.utc(2024, 2, 1)),
        _mark(67, 1, DateTime.utc(2024, 3, 1)),
        _mark(112, 1, DateTime.utc(2024, 1, 1)),
      ],
      newestFirst: true,
    );

    expect(groups.map((g) => g.surahId).toList(), [67, 112]);
    expect(groups[1].items.map((b) => b.ayahNo).toList(), [4, 1]);
  });

  test('surah order groups by surah then ayah', () {
    final groups = groupBookmarks(
      [
        _mark(112, 4, DateTime.utc(2024, 1, 2)),
        _mark(2, 286, DateTime.utc(2024, 5, 1)),
        _mark(112, 1, DateTime.utc(2024, 2, 1)),
      ],
      newestFirst: false,
    );

    expect(groups.map((g) => g.surahId).toList(), [2, 112]);
    expect(groups[1].items.map((b) => b.ayahNo).toList(), [1, 4]);
  });
}
