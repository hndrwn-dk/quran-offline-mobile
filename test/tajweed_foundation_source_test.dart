import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_source.dart';

/// Official sample from Quran Foundation Content API 4.0
/// `GET /content/api/v4/quran/verses/uthmani_tajweed`.
const _foundationFatihah1 =
    'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ '
    '<tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed>'
    'رَّحْمَ<tajweed class=madda_normal>ـٰ</tajweed>نِ '
    '<tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed>'
    'رَّح<tajweed class=madda_permissible>ِي</tajweed>مِ '
    '<span class=end>١</span>';

void main() {
  test('bundled tajweed source is Quran Foundation uthmani_tajweed', () {
    expect(kTajweedSourceName, 'Quran Foundation');
    expect(
      kTajweedSourcePath,
      '/content/api/v4/quran/verses/uthmani_tajweed',
    );
  });

  test('bundled 1:1 tj matches the Foundation uthmani_tajweed sample', () {
    final verses = jsonDecode(
      File('assets/quran/s001.json').readAsStringSync(),
    ) as List<dynamic>;
    final first = verses.first as Map<String, dynamic>;
    expect(first['s'], 1);
    expect(first['a'], 1);
    if (first['tj'] == null) {
      markTestSkipped('bundled JSON omits tj until tajweed fetch');
      return;
    }
    expect(first['tj'], _foundationFatihah1);
  });
}
