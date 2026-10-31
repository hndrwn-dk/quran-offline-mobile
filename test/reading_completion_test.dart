import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/review/reading_completion.dart';

Verse _verse(int surahId, int ayahNo, {int page = 1, int juz = 1}) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: page,
    juz: juz,
    arabic: 'test',
  );
}

void main() {
  group('isSurahCompletion', () {
    final verses = [_verse(2, 1), _verse(2, 2), _verse(2, 3)];

    test('true when the visible verse is the last ayah of the surah', () {
      expect(isSurahCompletion(const SurahSource(2), verses, 2), isTrue);
    });

    test('false before the last ayah', () {
      expect(isSurahCompletion(const SurahSource(2), verses, 1), isFalse);
    });

    test('false for non-surah readers', () {
      expect(isSurahCompletion(const JuzSource(1), verses, 2), isFalse);
      expect(isSurahCompletion(const PageSource(1), verses, 2), isFalse);
      expect(
        isSurahCompletion(const SurahInJuzSource(1, 2), verses, 2),
        isFalse,
      );
    });

    test('false for an empty verse list or out-of-range index', () {
      expect(isSurahCompletion(const SurahSource(2), const [], 0), isFalse);
      expect(isSurahCompletion(const SurahSource(2), verses, 3), isFalse);
    });
  });

  group('isLastPageOfJuz', () {
    test('true when the page is the last page of its juz', () {
      final juzVerses = [
        _verse(1, 1, page: 1, juz: 1),
        _verse(1, 7, page: 1, juz: 1),
        _verse(2, 1, page: 2, juz: 1),
        _verse(2, 141, page: 21, juz: 1),
      ];
      expect(
        isLastPageOfJuz(
          pageNo: 21,
          pageVerses: [_verse(2, 141, page: 21, juz: 1)],
          juzVerses: juzVerses,
        ),
        isTrue,
      );
    });

    test('false on an earlier page of the same juz', () {
      final juzVerses = [
        _verse(1, 1, page: 1, juz: 1),
        _verse(2, 141, page: 21, juz: 1),
      ];
      expect(
        isLastPageOfJuz(
          pageNo: 2,
          pageVerses: [_verse(2, 1, page: 2, juz: 1)],
          juzVerses: juzVerses,
        ),
        isFalse,
      );
    });

    test('false when page or juz verses are empty', () {
      expect(
        isLastPageOfJuz(pageNo: 1, pageVerses: const [], juzVerses: const []),
        isFalse,
      );
    });
  });
}
