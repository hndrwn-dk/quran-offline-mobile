import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Verses extends Table {
  IntColumn get surahId => integer()();
  IntColumn get ayahNo => integer()();
  IntColumn get page => integer()();
  IntColumn get juz => integer()();
  TextColumn get arabic => text()();
  TextColumn get tajweed => text().nullable()();
  TextColumn get translit => text().nullable()();
  TextColumn get translitTj => text().nullable()();
  TextColumn get trEn => text().nullable()();
  TextColumn get trId => text().nullable()();
  TextColumn get trZh => text().nullable()();
  TextColumn get trJa => text().nullable()();

  @override
  Set<Column> get primaryKey => {surahId, ayahNo};
}

class Bookmarks extends Table {
  IntColumn get surahId => integer()();
  IntColumn get ayahNo => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get folder => text().nullable()();
  TextColumn get tag => text().nullable()();
  IntColumn get color => integer().nullable()(); // Color value as int
  TextColumn get note => text().nullable()(); // Notes for bookmark

  @override
  Set<Column> get primaryKey => {surahId, ayahNo};
}

class Notes extends Table {
  IntColumn get surahId => integer()();
  IntColumn get ayahNo => integer()();
  TextColumn get note => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {surahId, ayahNo};
}

class Highlights extends Table {
  IntColumn get surahId => integer()();
  IntColumn get ayahNo => integer()();
  IntColumn get color => integer()(); // Color value as int
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {surahId, ayahNo};
}

/// Juz Amma (Juz 30) memorization — one row per completed ayah.
class MemorizationProgress extends Table {
  IntColumn get surahId => integer()();
  IntColumn get ayahNo => integer()();
  DateTimeColumn get completedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {surahId, ayahNo};
}

/// Self-marked Friday setoran completion (not a substitute for a teacher).
class SetoranLogs extends Table {
  TextColumn get fridayKey => text()();
  TextColumn get itemKey => text()();
  IntColumn get surahId => integer()();
  IntColumn get fromAyah => integer()();
  IntColumn get toAyah => integer()();
  DateTimeColumn get completedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {fridayKey, itemKey};
}

@DriftDatabase(
  tables: [Verses, Bookmarks, Notes, Highlights, MemorizationProgress, SetoranLogs],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await customStatement('CREATE INDEX IF NOT EXISTS idx_verses_page ON verses(page)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_verses_juz ON verses(juz)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_verses_surah_ayah ON verses(surah_id, ayah_no)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_notes_surah_ayah ON notes(surah_id, ayah_no)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_highlights_surah_ayah ON highlights(surah_id, ayah_no)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_bookmarks_folder ON bookmarks(folder)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_bookmarks_tag ON bookmarks(tag)');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add tajweed column
          await m.addColumn(verses, verses.tajweed);
        }
        if (from < 3) {
          // Add notes, highlights tables and bookmark organization fields
          await m.createTable(notes);
          await m.createTable(highlights);
          await m.addColumn(bookmarks, bookmarks.folder);
          await m.addColumn(bookmarks, bookmarks.tag);
          await m.addColumn(bookmarks, bookmarks.color);
          await m.addColumn(bookmarks, bookmarks.note);
          await customStatement('CREATE INDEX IF NOT EXISTS idx_notes_surah_ayah ON notes(surah_id, ayah_no)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_highlights_surah_ayah ON highlights(surah_id, ayah_no)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_bookmarks_folder ON bookmarks(folder)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_bookmarks_tag ON bookmarks(tag)');
        }
        if (from < 4) {
          await m.addColumn(verses, verses.translitTj);
        }
        if (from < 5) {
          await m.createTable(memorizationProgress);
        }
        if (from < 6) {
          await m.createTable(setoranLogs);
        }
      },
    );
  }

  Future<List<Verse>> getVersesBySurah(int surahId) {
    return (select(verses)
          ..where((v) => v.surahId.equals(surahId))
          ..orderBy([(v) => OrderingTerm(expression: v.ayahNo)]))
        .get();
  }

  Future<List<Verse>> getVersesByRange(int surahId, int startAyah, int endAyah) {
    return (select(verses)
          ..where((v) => v.surahId.equals(surahId) & v.ayahNo.isBiggerOrEqualValue(startAyah) & v.ayahNo.isSmallerOrEqualValue(endAyah))
          ..orderBy([(v) => OrderingTerm(expression: v.ayahNo)]))
        .get();
  }

  Future<List<Verse>> getVersesByJuz(int juzNo) {
    return (select(verses)
          ..where((v) => v.juz.equals(juzNo))
          ..orderBy([
            (v) => OrderingTerm(expression: v.surahId),
            (v) => OrderingTerm(expression: v.ayahNo),
          ]))
        .get();
  }

  Future<List<Verse>> getVersesBySurahInJuz(int surahId, int juzNo) {
    return (select(verses)
          ..where((v) => v.surahId.equals(surahId) & v.juz.equals(juzNo))
          ..orderBy([(v) => OrderingTerm(expression: v.ayahNo)]))
        .get();
  }

  Future<List<int>> getSurahIdsInJuz(int juzNo) async {
    final verses = await getVersesByJuz(juzNo);
    final surahIds = verses.map((v) => v.surahId).toSet().toList();
    surahIds.sort();
    return surahIds;
  }

  Future<int> getAyahCountForSurah(int surahId) async {
    final verses = await getVersesBySurah(surahId);
    return verses.length;
  }

  Future<List<Verse>> getVersesByPage(int pageNo) {
    return (select(verses)
          ..where((v) => v.page.equals(pageNo))
          ..orderBy([
            (v) => OrderingTerm(expression: v.surahId),
            (v) => OrderingTerm(expression: v.ayahNo),
          ]))
        .get();
  }

  Future<int?> getPageForAyah(int surahId, int ayahNo) async {
    final verse = await (select(verses)
          ..where((v) => v.surahId.equals(surahId) & v.ayahNo.equals(ayahNo))
          ..limit(1))
        .getSingleOrNull();
    return verse?.page;
  }

  Future<Verse?> getVerse(int surahId, int ayahNo) async {
    return await (select(verses)
          ..where((v) => v.surahId.equals(surahId) & v.ayahNo.equals(ayahNo))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Verse>> searchVerses(String query, String lang) {
    final langColumn = switch (lang) {
      'en' => verses.trEn,
      'id' => verses.trId,
      'zh' => verses.trZh,
      'ja' => verses.trJa,
      _ => verses.trId,
    };

    return (select(verses)
          ..where((v) => langColumn.like('%$query%'))
          ..orderBy([
            (v) => OrderingTerm(expression: v.surahId),
            (v) => OrderingTerm(expression: v.ayahNo),
          ])
          ..limit(100))
        .get();
  }

  Future<Bookmark?> getBookmark(int surahId, int ayahNo) {
    return (select(bookmarks)
          ..where((b) => b.surahId.equals(surahId) & b.ayahNo.equals(ayahNo))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> toggleBookmark(int surahId, int ayahNo) async {
    final existing = await getBookmark(surahId, ayahNo);
    if (existing != null) {
      await (delete(bookmarks)
            ..where((b) => b.surahId.equals(surahId) & b.ayahNo.equals(ayahNo)))
          .go();
    } else {
      await into(bookmarks).insert(
        BookmarksCompanion.insert(
          surahId: surahId,
          ayahNo: ayahNo,
        ),
      );
    }
  }

  Future<void> deleteBookmarks(List<Bookmark> items) async {
    for (final item in items) {
      await (delete(bookmarks)
            ..where(
              (b) => b.surahId.equals(item.surahId) & b.ayahNo.equals(item.ayahNo),
            ))
          .go();
    }
  }

  Future<void> deleteAllBookmarks() async {
    await delete(bookmarks).go();
  }

  Future<List<Bookmark>> getAllBookmarks() {
    return (select(bookmarks)
          ..orderBy([(b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // Notes methods
  Future<Note?> getNote(int surahId, int ayahNo) {
    return (select(this.notes)
          ..where((n) => n.surahId.equals(surahId) & n.ayahNo.equals(ayahNo))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> saveNote(int surahId, int ayahNo, String noteText) async {
    final existing = await getNote(surahId, ayahNo);
    if (existing != null) {
      await (update(this.notes)..where((n) => n.surahId.equals(surahId) & n.ayahNo.equals(ayahNo)))
          .write(NotesCompanion(
        note: Value(noteText),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await into(this.notes).insert(
        NotesCompanion.insert(
          surahId: surahId,
          ayahNo: ayahNo,
          note: noteText,
        ),
      );
    }
  }

  Future<void> deleteNote(int surahId, int ayahNo) async {
    await (delete(this.notes)
          ..where((n) => n.surahId.equals(surahId) & n.ayahNo.equals(ayahNo)))
        .go();
  }

  Future<List<Note>> getNotesBySurah(int surahId) {
    return (select(this.notes)
          ..where((n) => n.surahId.equals(surahId))
          ..orderBy([(n) => OrderingTerm(expression: n.ayahNo)]))
        .get();
  }

  Future<List<Note>> getAllNotes() {
    return (select(this.notes)
          ..orderBy([
            (n) => OrderingTerm(expression: n.surahId),
            (n) => OrderingTerm(expression: n.ayahNo),
          ]))
        .get();
  }

  // Highlights methods
  Future<Highlight?> getHighlight(int surahId, int ayahNo) {
    return (select(highlights)
          ..where((h) => h.surahId.equals(surahId) & h.ayahNo.equals(ayahNo))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> toggleHighlight(int surahId, int ayahNo, int color) async {
    final existing = await getHighlight(surahId, ayahNo);
    if (existing != null) {
      // If same color, remove highlight; otherwise update color
      if (existing.color == color) {
        await (delete(highlights)
              ..where((h) => h.surahId.equals(surahId) & h.ayahNo.equals(ayahNo)))
            .go();
      } else {
        await (update(highlights)..where((h) => h.surahId.equals(surahId) & h.ayahNo.equals(ayahNo)))
            .write(HighlightsCompanion(color: Value(color)));
      }
    } else {
      await into(highlights).insert(
        HighlightsCompanion.insert(
          surahId: surahId,
          ayahNo: ayahNo,
          color: color,
        ),
      );
    }
  }

  Future<void> removeHighlight(int surahId, int ayahNo) async {
    await (delete(highlights)
          ..where((h) => h.surahId.equals(surahId) & h.ayahNo.equals(ayahNo)))
        .go();
  }

  Future<List<Highlight>> getHighlightsBySurah(int surahId) {
    return (select(highlights)
          ..where((h) => h.surahId.equals(surahId))
          ..orderBy([(h) => OrderingTerm(expression: h.ayahNo)]))
        .get();
  }

  Future<List<Highlight>> getAllHighlights() {
    return (select(highlights)
          ..orderBy([
            (h) => OrderingTerm(expression: h.surahId),
            (h) => OrderingTerm(expression: h.ayahNo),
          ]))
        .get();
  }

  // Bookmark organization methods
  Future<void> updateBookmarkOrganization(
    int surahId,
    int ayahNo, {
    String? folder,
    String? tag,
    int? color,
    String? note,
  }) async {
    await (update(bookmarks)..where((b) => b.surahId.equals(surahId) & b.ayahNo.equals(ayahNo)))
        .write(BookmarksCompanion(
      folder: Value(folder),
      tag: Value(tag),
      color: Value(color),
      note: Value(note),
    ));
  }

  Future<List<String>> getAllFolders() async {
    final allBookmarks = await getAllBookmarks();
    final folders = allBookmarks
        .where((b) => b.folder != null && b.folder!.isNotEmpty)
        .map((b) => b.folder!)
        .toSet()
        .toList();
    folders.sort();
    return folders;
  }

  Future<List<String>> getAllTags() async {
    final allBookmarks = await getAllBookmarks();
    final tags = allBookmarks
        .where((b) => b.tag != null && b.tag!.isNotEmpty)
        .map((b) => b.tag!)
        .toSet()
        .toList();
    tags.sort();
    return tags;
  }

  Future<List<Bookmark>> getBookmarksByFolder(String folder) {
    return (select(bookmarks)
          ..where((b) => b.folder.equals(folder))
          ..orderBy([(b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<Bookmark>> getBookmarksByTag(String tag) {
    return (select(bookmarks)
          ..where((b) => b.tag.equals(tag))
          ..orderBy([(b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<bool> isAyahMemorized(int surahId, int ayahNo) async {
    final row = await (select(memorizationProgress)
          ..where((m) =>
              m.surahId.equals(surahId) & m.ayahNo.equals(ayahNo)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> setAyahMemorized(int surahId, int ayahNo, bool memorized) async {
    if (memorized) {
      await into(memorizationProgress).insertOnConflictUpdate(
        MemorizationProgressCompanion.insert(
          surahId: surahId,
          ayahNo: ayahNo,
        ),
      );
    } else {
      await (delete(memorizationProgress)
            ..where((m) =>
                m.surahId.equals(surahId) & m.ayahNo.equals(ayahNo)))
          .go();
    }
  }

  Future<List<MemorizationProgressData>> getJuzAmmaMemorization() {
    return (select(memorizationProgress)
          ..where((m) =>
              m.surahId.isBiggerOrEqualValue(78) &
              m.surahId.isSmallerOrEqualValue(114))
          ..orderBy([
            (m) => OrderingTerm(expression: m.surahId),
            (m) => OrderingTerm(expression: m.ayahNo),
          ]))
        .get();
  }

  Future<List<SetoranLog>> getSetoranLogsForFriday(String fridayKey) {
    return (select(setoranLogs)
          ..where((s) => s.fridayKey.equals(fridayKey))
          ..orderBy([
            (s) => OrderingTerm(expression: s.completedAt),
          ]))
        .get();
  }

  Future<void> markSetoranItemDone({
    required String fridayKey,
    required String itemKey,
    required int surahId,
    required int fromAyah,
    required int toAyah,
  }) async {
    await into(setoranLogs).insertOnConflictUpdate(
      SetoranLogsCompanion.insert(
        fridayKey: fridayKey,
        itemKey: itemKey,
        surahId: surahId,
        fromAyah: fromAyah,
        toAyah: toAyah,
      ),
    );
  }

  Future<void> unmarkSetoranItem(String fridayKey, String itemKey) async {
    await (delete(setoranLogs)
          ..where(
            (s) => s.fridayKey.equals(fridayKey) & s.itemKey.equals(itemKey),
          ))
        .go();
  }

  Future<int> countMemorizedAyahsInRange(
    int surahId,
    int fromAyah,
    int toAyah,
  ) async {
    final rows = await (select(memorizationProgress)
          ..where((m) =>
              m.surahId.equals(surahId) &
              m.ayahNo.isBiggerOrEqualValue(fromAyah) &
              m.ayahNo.isSmallerOrEqualValue(toAyah)))
        .get();
    return rows.length;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quran.db'));
    return NativeDatabase(file);
  });
}

