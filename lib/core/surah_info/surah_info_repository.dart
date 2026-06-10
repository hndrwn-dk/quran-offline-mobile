import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/models/surah_qul_info.dart';
import 'package:quran_offline/core/surah_info/surah_info_config.dart';
import 'package:quran_offline/core/surah_info/surah_info_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SurahInfoRepository {
  SurahInfoRepository();

  final Map<String, Database> _openByLanguage = {};
  Directory? _rootDir;

  Future<void> ensureLanguageReady(String qulLanguage) async {
    final assetPath = SurahInfoConfig.assetPathForLanguage(qulLanguage);
    if (assetPath == null) return;

    if (_openByLanguage.containsKey(qulLanguage)) return;

    _rootDir ??= await _surahInfoRoot();
    final fileName = SurahInfoConfig.fileNameForLanguage(qulLanguage);
    final localFile = File(p.join(_rootDir!.path, fileName));

    final prefs = await SharedPreferences.getInstance();
    final versionKey = 'surah_info_bundle_${qulLanguage}_v';
    final storedVersion = prefs.getInt(versionKey) ?? 0;

    if (!await localFile.exists() ||
        storedVersion != SurahInfoConfig.bundleVersion) {
      final bytes = await rootBundle.load(assetPath);
      await localFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      await prefs.setInt(versionKey, SurahInfoConfig.bundleVersion);
    }

    final db = await openDatabase(
      localFile.path,
      readOnly: true,
      singleInstance: true,
    );
    _openByLanguage[qulLanguage] = db;
  }

  Future<SurahQulInfoEntry?> getForSurah(
    String qulLanguage,
    int surahId,
  ) async {
    if (surahId < 1 || surahId > 114) return null;

    final assetPath = SurahInfoConfig.assetPathForLanguage(qulLanguage);
    if (assetPath == null) return null;

    await ensureLanguageReady(qulLanguage);
    final db = _openByLanguage[qulLanguage];
    if (db == null) return null;

    final rows = await db.query(
      'surah_infos',
      columns: ['text', 'short_text'],
      where: 'surah_number = ?',
      whereArgs: [surahId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final entry = SurahInfoHtml.parse(
      html: row['text'] as String?,
      shortText: row['short_text'] as String?,
      language: qulLanguage,
    );
    if (entry.isEmpty) return null;
    return entry;
  }

  Future<Directory> _surahInfoRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'surah_info'));
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
  }
}
