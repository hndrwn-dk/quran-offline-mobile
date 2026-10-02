import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/models/tafsir_entry.dart';
import 'package:quran_offline/core/tafsir/tafsir_config.dart';
import 'package:quran_offline/core/tafsir/tafsir_content_parser.dart';
import 'package:quran_offline/core/utils/async_once.dart';
import 'package:quran_offline/core/utils/sqlite_bundle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class TafsirRepository {
  TafsirRepository();

  final Map<String, Database> _openByLanguage = {};
  final Map<String, AsyncOnce> _ensureOnceByLanguage = {};
  Directory? _rootDir;

  static String _ayahKey(int surahId, int ayahNo) => '$surahId:$ayahNo';

  Future<void> ensureLanguageReady(String translationLanguage) {
    final assetPath = TafsirConfig.assetPathForLanguage(translationLanguage);
    if (assetPath == null) return Future.value();

    final once = _ensureOnceByLanguage.putIfAbsent(
      translationLanguage,
      AsyncOnce.new,
    );
    return once.run(
      () => _ensureLanguageReadyBody(translationLanguage, assetPath),
    );
  }

  Future<void> _ensureLanguageReadyBody(
    String translationLanguage,
    String assetPath,
  ) async {
    if (_openByLanguage.containsKey(translationLanguage)) return;

    _rootDir ??= await _tafsirRoot();
    final fileName = TafsirConfig.fileNameForLanguage(translationLanguage);
    final localFile = File(p.join(_rootDir!.path, fileName));

    final prefs = await SharedPreferences.getInstance();
    final versionKey = 'tafsir_bundle_${translationLanguage}_v';
    final storedVersion = prefs.getInt(versionKey) ?? 0;

    final copied = await openOrRecopySqliteFile(
      localFile: localFile,
      needsCopy: !await localFile.exists() ||
          storedVersion != TafsirConfig.bundleVersion,
      loadBytes: () async {
        final bytes = await rootBundle.load(assetPath);
        return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      },
      openAndValidate: (path) async {
        _openByLanguage[translationLanguage] =
            await openSqfliteReadOnlyValidated(path);
      },
    );
    if (copied) {
      await prefs.setInt(versionKey, TafsirConfig.bundleVersion);
    }
  }

  Future<TafsirEntry?> getForAyah(
    String translationLanguage,
    int surahId,
    int ayahNo,
  ) async {
    final assetPath = TafsirConfig.assetPathForLanguage(translationLanguage);
    if (assetPath == null) return null;

    await ensureLanguageReady(translationLanguage);
    final db = _openByLanguage[translationLanguage];
    if (db == null) return null;

    final key = _ayahKey(surahId, ayahNo);
    final row = await _queryRow(db, key);
    if (row == null) return null;

    var html = row['text'] as String? ?? '';
    final groupKey = row['group_ayah_key'] as String?;

    if (html.trim().isEmpty && groupKey != null && groupKey != key) {
      final groupRow = await _queryRow(db, groupKey);
      html = groupRow?['text'] as String? ?? '';
    }

    final content = TafsirContentParser.parse(html, translationLanguage);
    if (content.isEmpty) return null;

    return TafsirEntry(
      content: content,
      rangeLabel: _rangeLabel(row),
    );
  }

  Future<Map<String, Object?>?> _queryRow(Database db, String ayahKey) async {
    final rows = await db.query(
      'tafsir',
      columns: [
        'ayah_key',
        'group_ayah_key',
        'from_ayah',
        'to_ayah',
        'ayah_keys',
        'text',
      ],
      where: 'ayah_key = ?',
      whereArgs: [ayahKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  String? _rangeLabel(Map<String, Object?> row) {
    final from = row['from_ayah'] as String?;
    final to = row['to_ayah'] as String?;
    if (from != null &&
        to != null &&
        from.isNotEmpty &&
        to.isNotEmpty &&
        from != to) {
      return '$from – $to';
    }

    final keys = row['ayah_keys'] as String?;
    if (keys == null || keys.isEmpty) return null;
    final parts = keys.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final list = parts.toList();
    if (list.length <= 1) return null;
    return '${list.first} – ${list.last}';
  }

  Future<Directory> _tafsirRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'tafsir'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> dispose() async {
    for (final db in _openByLanguage.values) {
      await db.close();
    }
    _openByLanguage.clear();
    _ensureOnceByLanguage.clear();
  }
}
