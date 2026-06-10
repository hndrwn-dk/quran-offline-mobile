import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tafsir/tafsir_config.dart';

void main() {
  test('TafsirConfig maps all app translation languages', () {
    for (final lang in ['id', 'en', 'zh', 'ja']) {
      expect(TafsirConfig.assetPathForLanguage(lang), isNotNull);
      expect(TafsirConfig.fileNameForLanguage(lang), endsWith('.sqlite'));
    }
    expect(TafsirConfig.assetPathForLanguage('fr'), isNull);
  });
}
