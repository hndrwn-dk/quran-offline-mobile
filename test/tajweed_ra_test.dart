import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_html.dart';

void main() {
  test('untagged ra with fatha is not given a homemade tafkhim rule', () {
    expect(TajweedHtml.prepareForParsing('رَبِّكَ'), 'رَبِّكَ');
  });

  test('ra with kasra stays untagged', () {
    const input = 'الرِّجَال';
    expect(
      TajweedHtml.prepareForParsing(input),
      isNot(contains('class=tafkhim')),
    );
  });
}
