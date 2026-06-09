import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/surah_qul_info.dart';

void main() {
  test('qulSurahInfoLanguage follows translation, defaults to English', () {
    expect(qulSurahInfoLanguage('id'), 'id');
    expect(qulSurahInfoLanguage('en'), 'en');
    expect(qulSurahInfoLanguage('zh'), 'en');
    expect(qulSurahInfoLanguage('ja'), 'en');
  });
}
