import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';
import 'package:quran_offline/features/library/library_search.dart';

void main() {
  test('latin names ignore al-, spaces, and hyphens', () {
    expect(normalizeLibraryText('Al-Ikhlas'), 'ikhlas');
    expect(normalizeLibraryText('al ikhlas'), 'ikhlas');
    expect(normalizeLibraryText('al-ikhlas'), 'ikhlas');
    expect(normalizeLibraryText('AL-IKHLAS'), normalizeLibraryText('alikhlas'));
    expect(normalizeLibraryText("Ali 'Imran"), "ali'imran");
  });

  test('collapsed al- still matches the surah name', () {
    expect(libraryTextContains('Al-Ikhlas', 'alikhlas'), isTrue);
    expect(libraryTextContains('Al-Baqarah', 'baqarah'), isTrue);
    expect(libraryTextContains('Al-Ikhlas', 'ali'), isFalse);
  });

  test('reference matches s:a or a surah number', () {
    expect(libraryReferenceMatches('112:3', 112, 3), isTrue);
    expect(libraryReferenceMatches('112 : 3', 112, 3), isTrue);
    expect(libraryReferenceMatches('QS 2:286', 2, 286), isTrue);
    expect(libraryReferenceMatches('112:4', 112, 3), isFalse);
    expect(libraryReferenceMatches('112', 112, 3), isTrue);
    expect(libraryReferenceMatches('3', 112, 3), isFalse);
    expect(libraryReferenceMatches('2', 2, 286), isTrue);
  });

  test('entry matches translation, note, surah name, or reference', () {
    const hit = LibrarySearchItem(
      kind: LibrarySearchKind.note,
      surahId: 2,
      ayahNo: 286,
      surahName: 'Al-Baqarah',
      arabic: 'لَا يُكَلِّفُ ٱللَّهُ',
      translation: 'Allah tidak membebani seseorang',
      note: 'Pengingat waktu kerja lagi berat',
    );

    expect(libraryEntryMatches(hit, 'tidak'), isTrue);
    expect(libraryEntryMatches(hit, 'waktu kerja'), isTrue);
    expect(libraryEntryMatches(hit, 'baqarah'), isTrue);
    expect(libraryEntryMatches(hit, '2:286'), isTrue);
    expect(libraryEntryMatches(hit, 'fajar'), isFalse);
  });

  test('arabic query matches without harakat', () {
    const hit = LibrarySearchItem(
      kind: LibrarySearchKind.bookmark,
      surahId: 1,
      ayahNo: 1,
      surahName: 'Al-Fatihah',
      arabic: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ',
      translation: 'Dengan nama Allah',
      note: '',
    );

    expect(libraryEntryMatches(hit, 'الله'), isTrue);
    expect(libraryEntryMatches(hit, 'رحمن'), isTrue);
    final ranges = librarySnippetRanges(hit.arabic, 'الله');
    expect(ranges, isNotEmpty);
    final slice = hit.arabic.substring(ranges.first.start, ranges.first.end);
    expect(
      ArabicSearchNormalizer.normalizeForSearch(slice),
      contains(ArabicSearchNormalizer.normalizeForSearch('الله')),
    );
  });

  test('snippet marks each matched word', () {
    const text = 'Allah tidak membebani seseorang';
    final ranges = librarySnippetRanges(text, 'tidak');
    expect(ranges, hasLength(1));
    expect(text.substring(ranges.single.start, ranges.single.end), 'tidak');
  });
}
