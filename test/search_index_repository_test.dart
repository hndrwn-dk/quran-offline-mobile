import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/ai_search_config.dart';
import 'package:quran_offline/core/ai_search/id_query_normalizer.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void _writeMiniIndex(
  String path, {
  required String builtAt,
  required String marker,
}) {
  final db = sqlite3.open(path);
  db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  db.execute('''
    CREATE TABLE docs (
      doc_id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      lang TEXT NOT NULL,
      ref_key TEXT NOT NULL,
      surah INTEGER,
      ayah_from INTEGER,
      ayah_to INTEGER,
      title TEXT NOT NULL,
      body_norm TEXT NOT NULL
    )
  ''');
  db.execute('''
    CREATE VIRTUAL TABLE docs_fts USING fts5(
      title,
      body_norm,
      content='docs',
      content_rowid='rowid',
      tokenize='unicode61 remove_diacritics 2'
    )
  ''');
  db.execute(
    'INSERT INTO docs(doc_id, type, lang, ref_key, surah, ayah_from, ayah_to, title, body_norm) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    ['ayah:1:1:id', 'ayah', 'id', '1:1', 1, 1, 1, '1:1', marker],
  );
  db.execute(
    'INSERT INTO docs_fts(rowid, title, body_norm) VALUES (1, ?, ?)',
    ['1:1', marker],
  );
  db.execute(
    'INSERT INTO meta(key, value) VALUES (?, ?)',
    ['built_at_utc', builtAt],
  );
  db.dispose();
}

void main() {
  late Directory tmp;
  late String dbPath;
  late SearchIndexRepository repo;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('ai_search_idx');
    dbPath = '${tmp.path}/fixture.sqlite';
    final db = sqlite3.open(dbPath);
    db.execute(
      'CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    db.execute('''
      CREATE TABLE docs (
        doc_id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        lang TEXT NOT NULL,
        ref_key TEXT NOT NULL,
        surah INTEGER,
        ayah_from INTEGER,
        ayah_to INTEGER,
        title TEXT NOT NULL,
        body_norm TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE VIRTUAL TABLE docs_fts USING fts5(
        title,
        body_norm,
        content='docs',
        content_rowid='rowid',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    db.execute(
      'CREATE TABLE doc_refs (doc_id TEXT NOT NULL, surah INTEGER NOT NULL, ayah INTEGER NOT NULL)',
    );
    void addDoc({
      required String id,
      required String type,
      required String body,
      int? surah,
      int? ayah,
    }) {
      db.execute(
        '''
        INSERT INTO docs(doc_id, type, lang, ref_key, surah, ayah_from, ayah_to, title, body_norm)
        VALUES (?, ?, 'id', ?, ?, ?, ?, ?, ?)
        ''',
        [id, type, id, surah, ayah, ayah, id, body],
      );
      final rowid = db.lastInsertRowId;
      db.execute(
        'INSERT INTO docs_fts(rowid, title, body_norm) VALUES (?, ?, ?)',
        [rowid, id, body],
      );
      if (surah != null && ayah != null) {
        db.execute(
          'INSERT INTO doc_refs(doc_id, surah, ayah) VALUES (?, ?, ?)',
          [id, surah, ayah],
        );
      }
    }

    addDoc(id: 'ayah:2:1:id', type: 'ayah', body: 'alpha unique token', surah: 2, ayah: 1);
    addDoc(id: 'ayah:2:2:id', type: 'ayah', body: 'alpha shared token', surah: 2, ayah: 2);
    addDoc(id: 'dua:one:id', type: 'dua', body: 'alpha dua token', surah: 2, ayah: 1);
    addDoc(id: 'theme:x:id', type: 'theme', body: 'beta only token', surah: 3, ayah: 1);
    db.execute(
      "INSERT INTO meta(key, value) VALUES ('built_at_utc', '2026-01-01T00:00:00Z')",
    );
    db.dispose();

    repo = SearchIndexRepository();
  });

  tearDown(() {
    repo.close();
    tmp.deleteSync(recursive: true);
  });

  test('kAiSearchEnabled is true for v47', () {
    expect(kAiSearchEnabled, isTrue);
  });

  test('keywordSearch ranks better match first and respects type and limit', () async {
    await repo.openPath(dbPath, readOnly: false);
    final hits = await repo.keywordSearch('alpha', lang: 'id');
    expect(hits, isNotEmpty);
    expect(hits.first.score, greaterThanOrEqualTo(hits.last.score));
    expect(hits.every((h) => h.lang == 'id'), isTrue);

    final duas = await repo.keywordSearch(
      'alpha',
      types: {'dua'},
      lang: 'id',
    );
    expect(duas.every((h) => h.type == 'dua'), isTrue);
    expect(duas, isNotEmpty);

    final limited = await repo.keywordSearch('alpha', lang: 'id', limit: 1);
    expect(limited, hasLength(1));
  });

  test('relatedDocIds returns docs sharing an ayah', () async {
    await repo.openPath(dbPath, readOnly: false);
    final ids = await repo.relatedDocIds(2, 1);
    expect(ids, containsAll(['ayah:2:1:id', 'dua:one:id']));
    expect(ids, isNot(contains('ayah:2:2:id')));
  });

  test('ensureReady recopies when bundled asset built_at is newer than prefs',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      kSearchIndexBuiltAtPrefKey: '2020-01-01T00:00:00Z',
    });

    final docsDir = Directory('${tmp.path}/docs')..createSync();
    final localDir = Directory('${docsDir.path}/ai_search')..createSync();
    final localPath = '${localDir.path}/search_index.sqlite';
    _writeMiniIndex(
      localPath,
      builtAt: '2020-01-01T00:00:00Z',
      marker: 'oldmarker',
    );

    final bundledPath = '${tmp.path}/bundled.sqlite';
    _writeMiniIndex(
      bundledPath,
      builtAt: '2026-09-24T12:00:00Z',
      marker: 'newmarker',
    );
    final bundledBytes = File(bundledPath).readAsBytesSync();

    repo = SearchIndexRepository(
      documentsDirectory: docsDir,
      readBundledBytes: () async => bundledBytes,
    );
    await repo.ensureReady();

    final fresh = await repo.keywordSearch('newmarker', lang: 'id');
    expect(fresh, isNotEmpty, reason: 'recopy must expose bundled marker');
    final stale = await repo.keywordSearch('oldmarker', lang: 'id');
    expect(stale, isEmpty, reason: 'old local index must be replaced');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(kSearchIndexBuiltAtPrefKey),
      '2026-09-24T12:00:00Z',
    );
  });

  test('ftsAnyTermQuery joins terms with OR and keeps synonym groups', () {
    expect(ftsAnyTermQuery('doa orang tua'), 'doa OR orang OR tua');
    expect(
      ftsAnyTermQuery('(rezeki OR rizki) sabar'),
      '(rezeki OR rizki) OR sabar',
    );
  });

  test('doa untuk orang tua ranks both-terms above untuk-only', () async {
    final db = sqlite3.open(dbPath);
    void addDoc(String id, String body) {
      db.execute(
        '''
        INSERT INTO docs(doc_id, type, lang, ref_key, surah, ayah_from, ayah_to, title, body_norm)
        VALUES (?, 'ayah', 'id', ?, 2, 3, 3, ?, ?)
        ''',
        [id, id, id, body],
      );
      final rowid = db.lastInsertRowId;
      db.execute(
        'INSERT INTO docs_fts(rowid, title, body_norm) VALUES (?, ?, ?)',
        [rowid, id, body],
      );
    }

    addDoc('ayah:both:id', 'doa orang tua');
    addDoc('ayah:untuk:id', 'untuk');
    db.dispose();

    await repo.openPath(dbPath, readOnly: false);
    final query = IdQueryNormalizer.normalize('doa untuk orang tua');
    expect(query, 'doa orang tua');
    final hits = await repo.keywordSearch(query, lang: 'id');
    expect(hits, isNotEmpty);
    expect(hits.first.docId, 'ayah:both:id');
    final ids = [for (final hit in hits) hit.docId];
    if (ids.contains('ayah:untuk:id')) {
      expect(ids.indexOf('ayah:both:id'), lessThan(ids.indexOf('ayah:untuk:id')));
    }
  });
}
