import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _ayah(int surah, int ayah) {
  final file = File(
    'assets/quran/s${surah.toString().padLeft(3, '0')}.json',
  );
  final verses = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return verses.firstWhere((v) => (v as Map)['a'] == ayah) as Map<String, dynamic>;
}

void main() {
  test('bundled uthmani JSON omits tj/tl and uses U+0670 dagger alif', () {
    final fatihah = File('assets/quran/s001.json');
    if (!fatihah.existsSync()) {
      markTestSkipped('verse JSON not present in this checkout');
      return;
    }

    final v16 = _ayah(1, 6);
    expect(v16.containsKey('tj'), isFalse);
    expect(v16.containsKey('tl'), isFalse);
    expect(v16.containsKey('tl_tj'), isFalse);
    expect(v16['ar'] as String, contains('\u0670'));
    expect(v16['ar'] as String, isNot(contains('\u0672')));

    final v11 = _ayah(1, 1);
    expect(v11['ar'] as String, contains('\u0670'));
    expect(v11['ar'] as String, isNot(contains('\u0672')));

    final v644 = _ayah(6, 44);
    expect(v644['ar'] as String, contains('\u0670'));
    expect(v644['ar'] as String, isNot(contains('\u0672')));
  });
}
