import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/transliteration/transliteration_config.dart';
import 'package:quran_offline/core/utils/async_once.dart';
import 'package:quran_offline/core/utils/sqlite_bundle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class TransliterationRepository {
  TransliterationRepository();

  Database? _db;
  final AsyncOnce _ensureOnce = AsyncOnce();

  static String _ayahKey(int surahId, int ayahNo) => '$surahId:$ayahNo';

  Future<void> ensureReady() => _ensureOnce.run(_ensureReadyBody);

  Future<void> _ensureReadyBody() async {
    if (_db != null) return;

    final rootDir = await _transliterationRoot();
    final localFile = File(p.join(rootDir.path, TransliterationConfig.fileName));

    final prefs = await SharedPreferences.getInstance();
    const versionKey = 'transliteration_bundle_v';
    final storedVersion = prefs.getInt(versionKey) ?? 0;

    final copied = await openOrRecopySqliteFile(
      localFile: localFile,
      needsCopy: !await localFile.exists() ||
          storedVersion != TransliterationConfig.bundleVersion,
      loadBytes: () async {
        final bytes = await rootBundle.load(TransliterationConfig.assetPath);
        return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      },
      openAndValidate: (path) async {
        _db = await openSqfliteReadOnlyValidated(path);
      },
    );
    if (copied) {
      await prefs.setInt(versionKey, TransliterationConfig.bundleVersion);
    }
  }

  Future<String?> getForAyah(int surahId, int ayahNo) async {
    await ensureReady();
    final db = _db;
    if (db == null) return null;

    final rows = await db.query(
      'transliterations',
      columns: ['text'],
      where: 'ayah_key = ?',
      whereArgs: [_ayahKey(surahId, ayahNo)],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final text = rows.first['text'] as String?;
    if (text == null || text.trim().isEmpty) return null;
    return text.trim();
  }

  Future<Directory> _transliterationRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'transliteration'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
    _ensureOnce.reset();
  }
}
