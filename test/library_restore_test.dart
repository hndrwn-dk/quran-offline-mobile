import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTest(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('restoreBookmark keeps the original row and timestamp', () async {
    final created = DateTime.utc(2020, 5, 1, 12);
    final entry = Bookmark(
      surahId: 112,
      ayahNo: 3,
      createdAt: created,
      folder: 'pagi',
      tag: 'iman',
      color: 0xFF5A7358,
      note: 'hafalan',
      openContext: 'mushaf',
    );

    await db.restoreBookmark(entry);
    await db.deleteBookmarks([entry]);
    expect(await db.getBookmark(112, 3), isNull);

    await db.restoreBookmark(entry);
    final again = await db.getBookmark(112, 3);
    expect(again, isNotNull);
    expect(again!.surahId, 112);
    expect(again.ayahNo, 3);
    expect(again.createdAt.isAtSameMomentAs(created), isTrue);
    expect(again.folder, 'pagi');
    expect(again.tag, 'iman');
    expect(again.color, 0xFF5A7358);
    expect(again.note, 'hafalan');
    expect(again.openContext, 'mushaf');
  });

  test('restoreNote keeps body and both timestamps', () async {
    final created = DateTime.utc(2021, 1, 2, 3, 4, 5);
    final updated = DateTime.utc(2021, 6, 7, 8, 9, 10);
    final entry = Note(
      surahId: 2,
      ayahNo: 286,
      note: 'beban ini sudah dikur.',
      createdAt: created,
      updatedAt: updated,
    );

    await db.restoreNote(entry);
    await db.deleteNote(2, 286);
    await db.restoreNote(entry);

    final again = await db.getNote(2, 286);
    expect(again, isNotNull);
    expect(again!.note, 'beban ini sudah dikur.');
    expect(again.createdAt.isAtSameMomentAs(created), isTrue);
    expect(again.updatedAt.isAtSameMomentAs(updated), isTrue);
  });

  test('restoreHighlight keeps color and timestamp', () async {
    final created = DateTime.utc(2022, 8, 9, 10);
    final entry = Highlight(
      surahId: 67,
      ayahNo: 1,
      color: 0xFFC4920A,
      createdAt: created,
    );

    await db.restoreHighlight(entry);
    await db.removeHighlight(67, 1);
    await db.restoreHighlight(entry);

    final again = await db.getHighlight(67, 1);
    expect(again, isNotNull);
    expect(again!.color, 0xFFC4920A);
    expect(again.createdAt.isAtSameMomentAs(created), isTrue);
    expect(again.surahId, 67);
    expect(again.ayahNo, 1);
  });
}
