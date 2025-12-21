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

  @override
  Set<Column> get primaryKey => {surahId, ayahNo};
}

@DriftDatabase(tables: [Verses, Bookmarks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await customStatement('CREATE INDEX IF NOT EXISTS idx_verses_page ON verses(page)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_verses_juz ON verses(juz)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_verses_surah_ayah ON verses(surah_id, ayah_no)');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add tajweed column
          await m.addColumn(verses, verses.tajweed);
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quran.db'));
    return NativeDatabase(file);
  });
}

