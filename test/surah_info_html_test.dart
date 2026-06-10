import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/surah_info/surah_info_html.dart';

void main() {
  test('parses h2 sections from English surah info HTML', () {
    const html = '''
<h2>Name</h2>
<p>Named after Prophet Hud.</p>
<h2>Subject</h2>
<p>Invitation and warning.</p>
''';
    final entry = SurahInfoHtml.parse(
      html: html,
      shortText: 'Named after Prophet Hud.',
      language: 'en',
    );

    expect(entry.short, 'Named after Prophet Hud.');
    expect(entry.sections.length, 2);
    expect(entry.sections.first.title, 'Name');
    expect(entry.sections.first.body, contains('Prophet Hud'));
    expect(entry.sections.last.title, 'Subject');
  });

  test('parses Indonesian h2 Pokok-pokok sections (surah 1-10 format)', () {
    const html = '''
<p>Surat Al-An'am terdiri dari 165 ayat.</p>
<h3>Pokok-pokok Isi:</h3>
<h2>1. Keimanan:</h2>
<p>Bukti-bukti keesaan Allah.</p>
<h2>2. Hukum-hukum:</h2>
<p>Larangan mengikuti adat istiadat.</p>
''';
    final entry = SurahInfoHtml.parse(
      html: html,
      shortText: '',
      language: 'id',
    );

    expect(entry.short, contains('165 ayat'));
    expect(entry.sections.length, 2);
    expect(entry.sections.first.title, '1. Keimanan:');
    expect(entry.sections.first.body, contains('keesaan Allah'));
    expect(entry.sections.last.title, '2. Hukum-hukum:');
  });

  test('parses Indonesian markdown paragraph sections (surah 11+ format)', () {
    const html = '''
<p>Surat Hud termasuk surat Makkiyyah.</p>
<p>Surat ini dinamai Hud karena kisah Nabi Hud.</p>
<p>**Pokok-Pokok isi:**</p>
<p>1. **Keimanan:**</p>
<p>Keberadaan Arsy Allah.</p>
<p>2. **Hukum-hukum:**</p>
<p>Agama membolehkan menikmati yang baik-baik.</p>
<p>3. **Kisah-kisah:**</p>
<p>Kisah Nuh dan kaumnya.</p>
<p>4. **Lain-lain:**</p>
<p>Pelajaran dari kisah para nabi.</p>
<p>Surat Hud berisi pokok-pokok agama.</p>
<p>**Hubungan Surat Hud Dengan Surat Yusuf:**</p>
<p>1. Kedua surat ini sama-sama dimulai dengan alif laam raa.</p>
<p>2. Surat Yusuf menyempurnakan penjelasan kisah para rasul.</p>
<p>3. Perbedaan kedua surat ini ada dalam menjelaskan kisah-kisah.</p>
''';

    final entry = SurahInfoHtml.parse(
      html: html,
      shortText: '',
      language: 'id',
    );

    expect(entry.short, contains('Makkiyyah'));
    expect(entry.short, contains('dinamai Hud'));
    expect(entry.sections.length, 4);

    expect(entry.sections[0].title, '1. Keimanan:');
    expect(entry.sections[0].body, contains('Arsy Allah'));
    expect(entry.sections[0].body, isNot(contains('**')));

    expect(entry.sections[1].title, '2. Hukum-hukum:');
    expect(entry.sections[2].title, '3. Kisah-kisah:');
    expect(entry.sections[3].title, '4. Lain-lain:');
    expect(entry.sections[3].body, contains('pokok-pokok agama'));
    expect(
      entry.sections[3].body,
      contains('Hubungan Surat Hud Dengan Surat Yusuf:'),
    );
    expect(entry.sections[3].body, contains('alif laam raa'));
    expect(entry.sections[3].body, contains('2. Surat Yusuf menyempurnakan'));
    expect(entry.sections[3].body, contains('3. Perbedaan kedua surat'));
  });

  test('hubungan numbered list stays plain text inside Lain-lain', () {
    const html = '''
<p>4. **Lain-lain:**</p>
<p>Ringkasan lain-lain.</p>
<p>**Hubungan Surat Hud Dengan Surat Yusuf:**</p>
<p>1. Kedua surat ini sama-sama dimulai dengan alif laam raa.</p>
<p>2. Surat Yusuf menyempurnakan penjelasan kisah para rasul.</p>
<p>3. Perbedaan kedua surat ini ada dalam menjelaskan kisah-kisah.</p>
''';

    final entry = SurahInfoHtml.parse(html: html, shortText: '', language: 'id');

    expect(entry.sections.length, 1);
    expect(entry.sections.first.title, '4. Lain-lain:');
    expect(entry.sections.first.body, contains('Hubungan Surat Hud'));
    expect(entry.sections.first.body, contains('1. Kedua surat'));
    expect(entry.sections.first.body, contains('3. Perbedaan kedua surat'));
  });

  test('inline pokok surahs use supplementary body without collapse tiles', () {
    const html = '''
<p>Surat Al-Mulk terdiri dari 30 ayat.</p>
<p>**Pokok-Pokok Isi:**</p>
<p>Hidup dan mati adalah ujian bagi manusia.</p>
<p>Surat Al-Mulk menunjukkan bukti-bukti kebesaran Allah.</p>
<p>**Hubungan Surat Al-Mulk Dengan Surat Al-Qalam:**</p>
<p>Hubungan antara kedua surat ini.</p>
''';
    final entry = SurahInfoHtml.parse(
      html: html,
      shortText: '',
      language: 'id',
    );

    expect(entry.short, contains('30 ayat'));
    expect(entry.sections, isEmpty);
    expect(entry.supplementaryBody, contains('ujian bagi manusia'));
    expect(entry.supplementaryBody, contains('Hubungan Surat Al-Mulk'));
    expect(entry.supplementaryBody, isNot(contains('**')));
  });

  test('falls back to short text when only intro paragraphs exist', () {
    const html = '''
<p>Surat Hud termasuk surat Makkiyyah.</p>
<p>Surat ini dinamai Hud karena kisah Nabi Hud.</p>
''';
    final entry = SurahInfoHtml.parse(
      html: html,
      shortText: '',
      language: 'id',
    );

    expect(entry.short, contains('Makkiyyah'));
    expect(entry.short, contains('kisah Nabi Hud'));
    expect(entry.short, isNot(contains('**')));
    expect(entry.sections, isEmpty);
    expect(entry.supplementaryBody, isEmpty);
  });
}
