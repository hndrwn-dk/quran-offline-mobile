import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_html.dart';

void main() {
  test('does not invent tafkhim on untagged isti laa letters', () {
    const input = 'حَقُّ';
    expect(TajweedHtml.prepareForParsing(input), 'حَقُّ');
  });

  test('does not invent tafkhim on untagged ra with fatha', () {
    const input = 'رَبِّكَ';
    expect(
      TajweedHtml.prepareForParsing(input),
      isNot(contains('class=tafkhim')),
    );
  });

  test('keeps Foundation tafkhim tags unchanged', () {
    const input = 'أَ<tajweed class=tafkhim>ص</tajweed>حَ';
    expect(TajweedHtml.prepareForParsing(input), input);
  });

  test('strips U+06E1 without turning it into a homemade tafkhim tag', () {
    const input = 'أَص\u06e1حَ';
    final prepared = TajweedHtml.prepareForParsing(input);
    expect(prepared, 'أَصحَ');
    expect(prepared, isNot(contains('class=tafkhim')));
  });

  test('keeps Foundation ikhfa tag boundaries', () {
    const input = 'حْك<tajweed class=ikhafa_shafawi>ُم ب</tajweed>َيْنَ';
    expect(TajweedHtml.prepareForParsing(input), input);
  });

  test('keeps madda tatweel and dagger alif from Foundation HTML', () {
    const html = 'عَ<tajweed class=madda_normal>ـٰ</tajweed>لَ';
    final normalized = TajweedHtml.normalizeArabicForDisplay(html);
    expect(normalized, contains('ـٰ'));
    expect(normalized, contains('\u0670'));
  });

  test('keeps alef wasla from Foundation HTML', () {
    const html = '<tajweed class=ham_wasl>ٱ</tajweed>للَّهِ';
    final normalized = TajweedHtml.normalizeArabicForDisplay(html);
    expect(normalized, contains('\u0671'));
    expect(normalized, isNot(contains('اللَّهِ')));
  });

  test('display path does not rewrite JSON ar letters', () {
    const ar = 'أَنَا\u06df \u065f\u06a0';
    expect(TajweedHtml.normalizeArabicForDisplay(ar), ar);
  });
}
