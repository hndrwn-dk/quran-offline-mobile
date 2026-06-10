import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tafsir/tafsir_html.dart';

void main() {
  test('TafsirHtml strips tags and decodes entities', () {
    const html =
        '<p lang="en">Hello &amp; <b>world</b><br/>Line two</p>';
    final plain = TafsirHtml.toPlainText(html);
    expect(plain, contains('Hello & world'));
    expect(plain, contains('Line two'));
    expect(plain, isNot(contains('<')));
  });

  test('TafsirHtml returns empty for null or blank', () {
    expect(TafsirHtml.toPlainText(null), '');
    expect(TafsirHtml.toPlainText('   '), '');
  });

  test('TafsirHtml polishPlainText joins hyphenated line breaks', () {
    const raw = 'me-\n                  nafkahkan sebagian';
    expect(
      TafsirHtml.polishPlainText(raw),
      'menafkahkan sebagian',
    );
  });
}
