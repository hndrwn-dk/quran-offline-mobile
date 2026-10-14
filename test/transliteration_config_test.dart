import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/transliteration/transliteration_config.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('bundleVersion is 2 after QUL 40:85 yanfa typo fix', () {
    expect(TransliterationConfig.bundleVersion, 2);
  });

  test('QUL transliteration 40:85 says yanfa not tanfa', () {
    final file = File(TransliterationConfig.assetPath);
    if (!file.existsSync()) {
      markTestSkipped('bundled transliteration not on disk');
      return;
    }
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    addTearDown(db.dispose);
    final rows = db.select(
      "SELECT text FROM transliterations WHERE ayah_key = '40:85'",
    );
    expect(rows, isNotEmpty);
    final text = rows.first['text'] as String;
    expect(
      text,
      "Falam yaku yanfa-'uhum eemaanuhum lammaa ra-aw ba'sana sunnatal "
      "laahil latee qad khalat fee 'ibaadihee Wa-khasira hunaalikal kaafiroon",
    );
    expect(text.contains("tanfa-'uhum"), isFalse);
  });
}
