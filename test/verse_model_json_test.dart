import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/verse_model.dart';

void main() {
  test('VerseModel parses uthmani JSON without tj, tl, or tl_tj keys', () {
    final verse = VerseModel.fromJson({
      's': 1,
      'a': 6,
      'ar': 'صِرَٰطَ',
      'tr': {
        'en': 'the path',
        'id': 'jalan',
        'zh': '道路',
        'ja': '道',
      },
      'm': {
        'juz': 1,
        'page': 1,
        'hizb': 1,
        'ruku': 1,
      },
    });

    expect(verse.s, 1);
    expect(verse.a, 6);
    expect(verse.ar, 'صِرَٰطَ');
    expect(verse.tr?['en'], 'the path');
    expect(verse.m?.juz, 1);
    expect(verse.m?.page, 1);
    expect(verse.m?.hizb, 1);
    expect(verse.m?.ruku, 1);
  });
}
