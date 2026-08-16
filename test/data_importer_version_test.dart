import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/importer.dart';

void main() {
  test('currentVersion describes uthmani translations without tajweed or tl JSON', () {
    const version = DataImporter.currentVersion;
    expect(version, isNot(equals(
      'v9-uthmani+tajweed-words+tafkhim-heavy+translit+tl_tj+EN(SI)+ID(KEMENAG)+ZH(MaJian)+JA(Mita)-cleaned',
    )));
    expect(version.toLowerCase(), contains('uthmani'));
    expect(version.toLowerCase(), contains('no-tajweed-in-json'));
    expect(version.toLowerCase(), contains('no-tl'));
    expect(version.toLowerCase(), isNot(contains('tl_tj')));
    expect(version.toLowerCase(), isNot(contains('translit')));
    expect(version.toLowerCase(), isNot(contains('+tajweed')));
    expect(version, contains('EN(SI)'));
    expect(version, contains('ID(KEMENAG)'));
    expect(version, contains('ZH(MaJian)'));
    expect(version, contains('JA(Mita)'));
    expect(version, contains('fn-sup'));
  });
}
