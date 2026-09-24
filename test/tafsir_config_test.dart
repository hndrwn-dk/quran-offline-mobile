import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tafsir/tafsir_config.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('TafsirConfig maps all app translation languages', () {
    for (final lang in ['id', 'en', 'zh', 'ja']) {
      expect(TafsirConfig.assetPathForLanguage(lang), isNotNull);
      expect(TafsirConfig.fileNameForLanguage(lang), endsWith('.sqlite'));
    }
    expect(TafsirConfig.assetPathForLanguage('fr'), isNull);
  });

  test('bundleVersion is 2 after Qul Ibn Kathir 2:238 typo fix', () {
    expect(TafsirConfig.bundleVersion, 2);
  });

  test('English Ibn Kathir 2:238 says Asr prayer not Ar prayer', () {
    final file = File('assets/tafsir/en_ibn_kathir.sqlite');
    if (!file.existsSync()) {
      markTestSkipped('bundled tafsir not on disk');
      return;
    }
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    addTearDown(db.dispose);
    final rows = db.select(
      "SELECT text FROM tafsir WHERE ayah_key = '2:238'",
    );
    expect(rows, isNotEmpty);
    final text = rows.first['text'] as String;
    expect(text.contains("'Ar prayer"), isFalse);
    expect(text.contains("'Asr prayer"), isTrue);
  });
}
