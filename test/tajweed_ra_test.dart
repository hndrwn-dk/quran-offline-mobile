import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_html.dart';

void main() {
  test('ra with fatha in rabbika is tagged tafkhim', () {
    const input = 'رَبِّكَ';
    final prepared = TajweedHtml.prepareForParsing(input);
    expect(prepared, contains('<tajweed class=tafkhim>رَ</tajweed>'));
  });

  test('ra with kasra stays plain (tarqeeq)', () {
    const input = 'الرِّجَال';
    final prepared = TajweedHtml.prepareForParsing(input);
    expect(prepared, isNot(contains('<tajweed class=tafkhim>رِ')));
  });
}
