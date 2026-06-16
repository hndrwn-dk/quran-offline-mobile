import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/mushaf/qpc_v4_assets.dart';
import 'package:quran_offline/core/mushaf/qpc_v4_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Reads QUL QPC V4 layout + word glyph SQLite bundles.
class QpcV4Repository {
  QpcV4Repository();

  static const bundleVersion = 1;

  Database? _layoutDb;
  Database? _wordsDb;
  Directory? _rootDir;

  static Future<bool> assetsAvailable() async {
    try {
      await rootBundle.load(QpcV4Assets.layoutSqlite);
      await rootBundle.load(QpcV4Assets.wordsSqlite);
      await rootBundle.load(QpcV4Assets.pageFontAssetPath(1));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureReady() async {
    if (_layoutDb != null && _wordsDb != null) return;

    _rootDir ??= await _mushafRoot();
    final prefs = await SharedPreferences.getInstance();
    const versionKey = 'qpc_v4_mushaf_bundle_v';
    final storedVersion = prefs.getInt(versionKey) ?? 0;

    final layoutFile = File(p.join(_rootDir!.path, 'qpc_v4_layout.sqlite'));
    final wordsFile = File(p.join(_rootDir!.path, 'qpc_v4_words.sqlite'));

    if (!await layoutFile.exists() || storedVersion != bundleVersion) {
      final bytes = await rootBundle.load(QpcV4Assets.layoutSqlite);
      await layoutFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    if (!await wordsFile.exists() || storedVersion != bundleVersion) {
      final bytes = await rootBundle.load(QpcV4Assets.wordsSqlite);
      await wordsFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    if (storedVersion != bundleVersion) {
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

  Future<QpcV4PageContent> getPageContent(
    int pageNumber, {
    required String fontFamily,
  }) async {
    await ensureReady();
    final layoutDb = _layoutDb!;
    final wordsDb = _wordsDb!;

    final lineRows = await layoutDb.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    int? pageSurahId;
    final lines = <QpcV4Line>[];

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

      if (lineType == 'surah_name' && surahId != null) {
        pageSurahId = surahId;
      }

      if (lineType == 'basmallah') {
        lines.add(
          QpcV4Line(
            lineNumber: row['line_number'] as int,
            lineType: lineType,
            isCentered: isCentered,
            surahId: pageSurahId,
          ),
        );
        continue;
      }

      if (lineType == 'surah_name') {
        lines.add(
          QpcV4Line(
            lineNumber: row['line_number'] as int,
            lineType: lineType,
            isCentered: isCentered,
            surahId: surahId,
          ),
        );
        continue;
      }

      if (lineType != 'ayah') continue;

      final firstRaw = row['first_word_id'];
      final lastRaw = row['last_word_id'];
      if (firstRaw == null || lastRaw == null) continue;
      final first = _asInt(firstRaw);
      final last = _asInt(lastRaw);
      if (first == null || last == null) continue;

      final wordRows = await wordsDb.query(
        'words',
        where: 'id >= ? AND id <= ?',
        whereArgs: [first, last],
        orderBy: 'id ASC',
      );

      final words = wordRows
          .map(
            (w) => QpcV4Word(
              id: w['id'] as int,
              surah: w['surah'] as int,
              ayah: w['ayah'] as int,
              word: w['word'] as int,
              glyph: w['text'] as String,
              location: w['location'] as String,
            ),
          )
          .toList();

      lines.add(
        QpcV4Line(
          lineNumber: row['line_number'] as int,
          lineType: lineType,
          isCentered: isCentered,
          words: words,
        ),
      );
    }

    return QpcV4PageContent(
      pageNumber: pageNumber,
      lines: lines,
      fontFamily: fontFamily,
    );
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
    final dir = Directory(p.join(docs.path, 'qpc_v4_mushaf'));
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
