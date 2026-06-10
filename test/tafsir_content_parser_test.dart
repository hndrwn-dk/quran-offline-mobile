import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tafsir/tafsir_content_parser.dart';

void main() {
  test('Indonesian parser skips translation quote and keeps id/ms commentary', () {
    const html = '''
<p class="ms translation" lang="ms">"Alif lam mim..."</p>
<p lang="hi-Latn" class="hi-Latn ">Madaniyah</p>
<div lang="id" class="id ">
<span class="green">(1)</span> Huruf-huruf yang terpenggal-penggal di setiap awal surat.
</div>
<div lang="ms" class="ms ">
<span class="green">(2)</span> FirmanNya, tidak ada keraguan padanya.
</div>
''';

    final content = TafsirContentParser.parse(html, 'id');
    expect(content.revelationType, 'Madaniyah');
    expect(content.sections.length, 1);
    expect(content.sections.first.paragraphs.length, 2);
    expect(content.sections.first.paragraphs.first.label, '(1)');
    expect(
      content.sections.first.paragraphs.first.text,
      contains('Huruf-huruf'),
    );
    expect(content.plainText, isNot(contains('Alif lam mim')));
  });

  test('English parser keeps section headings and commentary', () {
    const html = '''
<p lang="en" class="en ">Intro paragraph.</p>
<div lang="jv" class="jv "><h2>The Virtue of Ayat Al-Kursi</h2></div>
<p lang="en" class="en ">This is Ayat Al-Kursi and tremendous virtues.</p>
''';

    final content = TafsirContentParser.parse(html, 'en');
    expect(content.sections.length, 2);
    expect(content.sections.last.title, 'The Virtue of Ayat Al-Kursi');
    expect(
      content.sections.last.paragraphs.first.text,
      contains('tremendous virtues'),
    );
  });

  test('Japanese parser accepts plain paragraph HTML', () {
    const html =
        '<p>慈悲あまねく、慈悲深いアッラーの御名において。</p>';
    final content = TafsirContentParser.parse(html, 'ja');
    expect(content.sections.first.paragraphs.first.text, contains('慈悲'));
  });
}
