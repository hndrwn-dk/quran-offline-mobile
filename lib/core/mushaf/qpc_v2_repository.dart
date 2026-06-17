import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_assets.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Reads QUL QPC V2 layout + word glyph SQLite bundles.
class QpcV2Repository {
  QpcV2Repository();

  static const bundleVersion = 3;
  static const layoutCacheVersion = 7;
  static const _pageCacheLimit = 32;

  static final Map<int, List<QpcV2Line>> _pageLinesCache = {};
  static final List<int> _pageCacheOrder = [];
  static final Set<int> _validatedPages = {};
  static bool _layoutCacheVersionChecked = false;
  static String? _bismillahGlyphTextCache;

  Database? _layoutDb;
  Database? _wordsDb;
  Directory? _rootDir;

  static Future<bool> assetsAvailable() async {
    try {
      await rootBundle.load(QpcV2Assets.layoutSqlite);
      await rootBundle.load(QpcV2Assets.wordsSqlite);
      await rootBundle.load(QpcV2Assets.pageFontAssetPath(1));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureReady() async {
    if (_layoutDb != null && _wordsDb != null) return;

    _rootDir ??= await _mushafRoot();
    final prefs = await SharedPreferences.getInstance();
    const versionKey = 'qpc_v2_mushaf_bundle_v';
    final storedVersion = prefs.getInt(versionKey) ?? 0;

    final layoutFile = File(p.join(_rootDir!.path, 'qpc_v2_layout.sqlite'));
    final wordsFile = File(p.join(_rootDir!.path, 'qpc_v2_words.sqlite'));

    if (!await layoutFile.exists() || storedVersion != bundleVersion) {
      final bytes = await rootBundle.load(QpcV2Assets.layoutSqlite);
      await layoutFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    if (!await wordsFile.exists() || storedVersion != bundleVersion) {
      final bytes = await rootBundle.load(QpcV2Assets.wordsSqlite);
      await wordsFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    if (storedVersion != bundleVersion) {
      _pageLinesCache.clear();
      _pageCacheOrder.clear();
      _validatedPages.clear();
      _layoutCacheVersionChecked = false;
      _bismillahGlyphTextCache = null;
      await prefs.setInt(versionKey, bundleVersion);
    }

    _layoutDb ??= await openDatabase(
      layoutFile.path,
      readOnly: true,
      singleInstance: true,
    );
    _wordsDb ??= await openDatabase(
      wordsFile.path,
      readOnly: true,
      singleInstance: true,
    );
  }

  Future<List<QpcV2Line>> getPageLines(int pageNumber) async {
    await _ensureLayoutCacheVersion();

    final cached = _pageLinesCache[pageNumber];
    if (cached != null) {
      if (_validatedPages.contains(pageNumber)) {
        _touchPageCache(pageNumber);
        return cached;
      }
      if (!await _isPageCacheValid(pageNumber, cached)) {
        _pageLinesCache.remove(pageNumber);
        _pageCacheOrder.remove(pageNumber);
        _validatedPages.remove(pageNumber);
      } else {
        _validatedPages.add(pageNumber);
        _touchPageCache(pageNumber);
        return cached;
      }
    }

    final lines = await _loadPageLines(pageNumber);
    _storePageCache(pageNumber, lines);
    _validatedPages.add(pageNumber);
    return lines;
  }

  /// Joined PUA glyphs for standalone Bismillah (words 1–4; word 5 is ayah marker).
  Future<String> bismillahGlyphText() async {
    if (_bismillahGlyphTextCache != null) return _bismillahGlyphTextCache!;

    await ensureReady();
    final wordRows = await _wordsDb!.query(
      'words',
      where: 'id >= ? AND id <= ?',
      whereArgs: [
        QpcV2Assets.bismillahFirstWordId,
        QpcV2Assets.bismillahStandaloneLastWordId,
      ],
      orderBy: 'id ASC',
    );

    _bismillahGlyphTextCache =
        wordRows.map((w) => w['text'] as String).join();
    return _bismillahGlyphTextCache!;
  }

  Future<List<QpcV2Line>> _loadPageLines(int pageNumber) async {
    await ensureReady();
    final layoutDb = _layoutDb!;
    final wordsDb = _wordsDb!;

    final lineRows = await layoutDb.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    int? lastSurahNameId;
    final ayahRanges = <({int lineNumber, bool isCentered, int first, int last})>[];
    final lines = <QpcV2Line>[];

    for (final row in lineRows) {
      final lineType = row['line_type'] as String;
      final isCentered = (row['is_centered'] as int? ?? 0) == 1;
      final surahRaw = row['surah_number'];
      int? surahId;
      if (surahRaw is int) {
        surahId = surahRaw;
      } else if (surahRaw is String && surahRaw.isNotEmpty) {
        surahId = int.tryParse(surahRaw);
      }

      if (lineType == 'surah_name') {
        lastSurahNameId = surahId;
        lines.add(
          QpcV2Line(
            lineNumber: row['line_number'] as int,
            lineType: lineType,
            isCentered: isCentered,
            surahId: surahId,
          ),
        );
        continue;
      }

      if (lineType == 'basmallah') {
        // Basmallah is rendered as Unicode (UthmanicHafsV22), not page PUA glyphs.
        lines.add(
          QpcV2Line(
            lineNumber: row['line_number'] as int,
            lineType: lineType,
            isCentered: isCentered,
            surahId: lastSurahNameId,
          ),
        );
        continue;
      }

      if (lineType != 'ayah') continue;

      final first = _asInt(row['first_word_id']);
      final last = _asInt(row['last_word_id']);
      if (first == null || last == null) continue;

      ayahRanges.add((
        lineNumber: row['line_number'] as int,
        isCentered: isCentered,
        first: first,
        last: last,
      ));
    }

    if (ayahRanges.isNotEmpty) {
      final minId = ayahRanges.map((r) => r.first).reduce((a, b) => a < b ? a : b);
      final maxId = ayahRanges.map((r) => r.last).reduce((a, b) => a > b ? a : b);

      final wordRows = await wordsDb.query(
        'words',
        where: 'id >= ? AND id <= ?',
        whereArgs: [minId, maxId],
        orderBy: 'id ASC',
      );

      final wordsById = <int, QpcV2Word>{
        for (final w in wordRows)
          w['id'] as int: QpcV2Word(
            id: w['id'] as int,
            surah: w['surah'] as int,
            ayah: w['ayah'] as int,
            word: w['word'] as int,
            glyph: w['text'] as String,
            location: w['location'] as String,
          ),
      };

      for (final range in ayahRanges) {
        final words = <QpcV2Word>[];
        for (var id = range.first; id <= range.last; id++) {
          final word = wordsById[id];
          if (word != null) words.add(word);
        }
        lines.add(
          QpcV2Line(
            lineNumber: range.lineNumber,
            lineType: 'ayah',
            isCentered: range.isCentered,
            words: words,
          ),
        );
      }
    }

    lines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    return lines;
  }

  Future<void> _ensureLayoutCacheVersion() async {
    if (_layoutCacheVersionChecked) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('qpc_v2_layout_cache_v') ?? 0;
    if (stored != layoutCacheVersion) {
      _pageLinesCache.clear();
      _pageCacheOrder.clear();
      _validatedPages.clear();
      _bismillahGlyphTextCache = null;
      await prefs.setInt('qpc_v2_layout_cache_v', layoutCacheVersion);
    }
    _layoutCacheVersionChecked = true;
  }

  static void clearPageCache() {
    _pageLinesCache.clear();
    _pageCacheOrder.clear();
    _validatedPages.clear();
    _layoutCacheVersionChecked = false;
    _bismillahGlyphTextCache = null;
  }

  /// Synchronous cache hit for already-loaded pages (swipe / revisit).
  static List<QpcV2Line>? peekCachedLines(int pageNumber) {
    return _pageLinesCache[pageNumber];
  }

  /// True when cached lines match layout DB (e.g. basmallah row present).
  Future<bool> _isPageCacheValid(int pageNumber, List<QpcV2Line> cached) async {
    await ensureReady();
    final layoutRows = await _layoutDb!.query(
      'pages',
      columns: ['line_type'],
      where: 'page_number = ?',
      whereArgs: [pageNumber],
    );

    final layoutBasmallah =
        layoutRows.where((r) => r['line_type'] == 'basmallah').length;
    final cacheBasmallah = cached.where((l) => l.isBasmallah).toList();

    if (layoutBasmallah > 0) {
      if (cacheBasmallah.length < layoutBasmallah) return false;
      for (final line in cacheBasmallah) {
        if (line.words.isNotEmpty) return false;
      }
    }

    return true;
  }

  static void _touchPageCache(int pageNumber) {
    _pageCacheOrder.remove(pageNumber);
    _pageCacheOrder.add(pageNumber);
  }

  static void _storePageCache(int pageNumber, List<QpcV2Line> lines) {
    _pageLinesCache[pageNumber] = lines;
    _touchPageCache(pageNumber);
    while (_pageCacheOrder.length > _pageCacheLimit) {
      final evict = _pageCacheOrder.removeAt(0);
      _pageLinesCache.remove(evict);
      _validatedPages.remove(evict);
    }
  }

  Future<bool> pageContainsRecitation(
    int pageNumber,
    int surahId,
    int ayahNo,
  ) async {
    await ensureReady();
    final layoutDb = _layoutDb!;

    final lineRows = await layoutDb.query(
      'pages',
      columns: ['first_word_id', 'last_word_id'],
      where: 'page_number = ? AND line_type = ?',
      whereArgs: [pageNumber, 'ayah'],
    );

    for (final row in lineRows) {
      final first = _asInt(row['first_word_id']);
      final last = _asInt(row['last_word_id']);
      if (first == null || last == null) continue;

      final match = await _wordsDb!.rawQuery(
        '''
        SELECT 1 FROM words
        WHERE id >= ? AND id <= ?
          AND surah = ? AND ayah = ?
        LIMIT 1
        ''',
        [first, last, surahId, ayahNo],
      );
      if (match.isNotEmpty) return true;
    }
    return false;
  }

  Future<List<int>> getSurahIdsForPage(int pageNumber) async {
    await ensureReady();
    final layoutDb = _layoutDb!;

    final ids = <int>{};
    final nameRows = await layoutDb.query(
      'pages',
      columns: ['surah_number'],
      where: 'page_number = ? AND line_type = ?',
      whereArgs: [pageNumber, 'surah_name'],
    );
    for (final row in nameRows) {
      final id = _asInt(row['surah_number']);
      if (id != null) ids.add(id);
    }

    final lineRows = await layoutDb.query(
      'pages',
      columns: ['first_word_id', 'last_word_id'],
      where: 'page_number = ? AND line_type = ?',
      whereArgs: [pageNumber, 'ayah'],
    );
    for (final row in lineRows) {
      final first = _asInt(row['first_word_id']);
      final last = _asInt(row['last_word_id']);
      if (first == null || last == null) continue;
      final surahRows = await _wordsDb!.rawQuery(
        '''
        SELECT DISTINCT surah FROM words
        WHERE id >= ? AND id <= ?
        ORDER BY surah ASC
        ''',
        [first, last],
      );
      for (final s in surahRows) {
        ids.add(s['surah'] as int);
      }
    }

    final sorted = ids.toList()..sort();
    return sorted;
  }

  Future<bool> pageHasBasmallahForSurah(int pageNumber, int surahId) async {
    await ensureReady();
    final rows = await _layoutDb!.query(
      'pages',
      where: 'page_number = ? AND line_type = ?',
      whereArgs: [pageNumber, 'basmallah'],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    // Basmallah follows surah_name on the same page; resolve surah from name line.
    final nameRows = await _layoutDb!.query(
      'pages',
      columns: ['surah_number', 'line_number'],
      where: 'page_number = ? AND line_type = ?',
      whereArgs: [pageNumber, 'surah_name'],
      orderBy: 'line_number ASC',
    );
    for (final name in nameRows) {
      final id = _asInt(name['surah_number']);
      final nameLine = name['line_number'] as int;
      final basmRows = await _layoutDb!.query(
        'pages',
        where:
            'page_number = ? AND line_type = ? AND line_number > ? AND line_number < ?',
        whereArgs: [pageNumber, 'basmallah', nameLine, nameLine + 4],
        limit: 1,
      );
      if (basmRows.isNotEmpty && id == surahId) return true;
    }
    return false;
  }

  Future<void> dispose() async {
    await _layoutDb?.close();
    await _wordsDb?.close();
    _layoutDb = null;
    _wordsDb = null;
  }

  Future<Directory> _mushafRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'qpc_v2_mushaf'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is String && value.isNotEmpty) return int.tryParse(value);
    return null;
  }
}
