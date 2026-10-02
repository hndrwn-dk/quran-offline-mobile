import 'dart:io';

import 'package:quran_offline/core/utils/atomic_file_write.dart';
import 'package:sqflite/sqflite.dart';

/// Opens [localFile], or recopies from [loadBytes] if missing/stale/unreadable.
///
/// Returns whether a copy ran so callers can stamp version prefs only after a
/// successful open. A copy that still fails to open is rethrown.
Future<bool> openOrRecopySqliteFile({
  required File localFile,
  required bool needsCopy,
  required Future<List<int>> Function() loadBytes,
  required Future<void> Function(String path) openAndValidate,
}) async {
  var copied = needsCopy || !await localFile.exists();

  Future<void> copy() async {
    await writeBytesAtomically(localFile, await loadBytes());
    copied = true;
  }

  if (copied) {
    await copy();
  }
  try {
    await openAndValidate(localFile.path);
  } catch (_) {
    await copy();
    await openAndValidate(localFile.path);
  }
  return copied;
}

Future<Database> openSqfliteReadOnlyValidated(String path) async {
  final db = await openDatabase(
    path,
    readOnly: true,
    singleInstance: true,
  );
  try {
    await db.rawQuery('SELECT 1 FROM sqlite_master LIMIT 1');
  } catch (_) {
    await db.close();
    rethrow;
  }
  return db;
}
