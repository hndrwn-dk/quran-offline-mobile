import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/share/verse_share_content.dart';

Verse _verse({
  required int surahId,
  required int ayahNo,
  required String arabic,
  String? trId,
}) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: 1,
    juz: 1,
    arabic: arabic,
    trId: trId ?? 'Terjemahan',
  );
}

void main() {
  final settings = AppSettings(
    language: 'id',
    appLanguage: 'id',
  );

  const longTranslation =
      'Mereka berkata, "Celakalah kami! Siapakah yang membangkitkan kami dari tempat tidur kami (kubur)?" Inilah yang dijanjikan (Allah) Yang Maha Pengasih dan benarlah rasul-rasul(-Nya).';

  test('share caption includes Arabic, full translation, and clickable Play URL',
      () {
    final content = VerseShareContent.from(
      verse: _verse(
        surahId: 36,
        ayahNo: 52,
        arabic:
            'قَالُوا يَا وَيْلَنَا مَن بَعَثَنَا مِن مَّرْقَدِنَا',
        trId: longTranslation,
      ),
      surahName: 'Ya-Sin',
      settings: settings,
    );

    final caption = content.buildShareCaption();
    expect(caption, contains('قَالُوا'));
    expect(caption, contains(longTranslation));
    expect(caption, isNot(contains('…')));
    expect(
      caption,
      contains(
        'https://play.google.com/store/apps/details?id=com.tursinalabs.quranoffline&hl=id',
      ),
    );
    expect(
      caption,
      contains(
        '\n\nhttps://play.google.com/store/apps/details?id=com.tursinalabs.quranoffline&hl=id',
      ),
    );
  });

  test('short ayah caption also includes Arabic', () {
    final content = VerseShareContent.from(
      verse: _verse(
        surahId: 112,
        ayahNo: 1,
        arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      ),
      surahName: 'Al-Ikhlas',
      settings: settings,
    );

    final caption = content.buildShareCaption();
    expect(caption, contains('قُلْ هُوَ'));
    expect(caption, contains('Terjemahan'));
    expect(caption, contains('https://play.google.com'));
  });

  test('play store URL follows translation locale', () {
    final idContent = VerseShareContent.from(
      verse: _verse(surahId: 112, ayahNo: 1, arabic: 'قُلْ'),
      surahName: 'Al-Ikhlas',
      settings: settings,
    );
    expect(idContent.playStoreUrl, contains('hl=id'));

    final enSettings = settings.copyWith(language: 'en', appLanguage: 'en');
    final enContent = VerseShareContent.from(
      verse: _verse(surahId: 112, ayahNo: 1, arabic: 'قُلْ'),
      surahName: 'Al-Ikhlas',
      settings: enSettings,
    );
    expect(enContent.playStoreUrl, contains('hl=en'));
  });
}
