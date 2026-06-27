import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/share/verse_share_content.dart';

Verse _verse({
  required int surahId,
  required int ayahNo,
  required String arabic,
  String? tajweed,
}) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: 1,
    juz: 1,
    arabic: arabic,
    tajweed: tajweed,
    trId: 'Terjemahan',
  );
}

void main() {
  final settings = AppSettings(
    language: 'id',
    appLanguage: 'id',
    showTajweed: false,
  );

  test('short ayah fits share card', () {
    final content = VerseShareContent.from(
      verse: _verse(
        surahId: 112,
        ayahNo: 1,
        arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      ),
      surahName: 'Al-Ikhlas',
      settings: settings,
    );

    expect(content.fitsShareCard, isTrue);
    expect(content.estimateArabicLineCount(), lessThanOrEqualTo(5));
  });

  test('long ayah uses text-only path', () {
    final longArabic = List.filled(40, 'وَاللَّهُ عَلِيمٌ حَكِيمٌ ').join();
    final content = VerseShareContent.from(
      verse: _verse(
        surahId: 2,
        ayahNo: 286,
        arabic: longArabic,
      ),
      surahName: 'Al-Baqarah',
      settings: settings,
    );

    expect(content.fitsShareCard, isFalse);
    expect(content.estimateArabicLineCount(), greaterThan(5));
  });

  test('text-only caption includes Arabic', () {
    final content = VerseShareContent.from(
      verse: _verse(
        surahId: 2,
        ayahNo: 286,
        arabic: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
      ),
      surahName: 'Al-Baqarah',
      settings: settings,
    );

    final caption = content.buildShareCaption(includeArabicInText: true);
    expect(caption, contains('لَا يُكَلِّفُ'));
    expect(caption, contains('Terjemahan'));
    expect(caption, contains('play.google.com'));
    expect(caption, contains('id=com.tursinalabs.quranoffline'));
    expect(caption, contains('hl=id'));
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

  test('card caption omits Arabic when image carries it', () {
    final content = VerseShareContent.from(
      verse: _verse(
        surahId: 112,
        ayahNo: 1,
        arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      ),
      surahName: 'Al-Ikhlas',
      settings: settings,
    );

    final caption = content.buildShareCaption(includeArabicInText: false);
    expect(caption, isNot(contains('قُلْ هُوَ')));
    expect(caption, contains('Terjemahan'));
  });
}
