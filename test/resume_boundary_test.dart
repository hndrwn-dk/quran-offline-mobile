import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/startup/resume_boundary.dart';

Verse _verse(int surahId, int ayahNo, {required int page, required int juz}) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: page,
    juz: juz,
    arabic: 'test',
  );
}

List<Verse> _fatihah({int juz = 1}) {
  return [
    for (var ayah = 1; ayah <= 7; ayah++) _verse(1, ayah, page: 1, juz: juz),
  ];
}

List<Verse> _baqarah({required int upTo, int juz = 1, int page = 2}) {
  return [
    for (var ayah = 1; ayah <= upTo; ayah++)
      _verse(2, ayah, page: page, juz: juz),
  ];
}

void main() {
  group('computeSurahResumeBoundary', () {
    test('Al-Fatihah mid-surah points at the surah end', () {
      final surah = _fatihah();
      final juz = [..._fatihah(), ..._baqarah(upTo: 141)];

      final boundary = computeSurahResumeBoundary(
        surahVerses: surah,
        verseIndex: 4, // Al-Fatihah 5
        juzVerses: juz,
      );

      expect(boundary, isNotNull);
      expect(boundary!.kind, ResumeBoundaryKind.surahEnd);
      expect(boundary.remaining, 2); // ayahs 6 and 7
    });

    test('Al-Baqarah mid-surah points at the juz end when closer', () {
      final surah = _baqarah(upTo: 286);
      final juz = [..._fatihah(), ..._baqarah(upTo: 141)];

      final boundary = computeSurahResumeBoundary(
        surahVerses: surah,
        verseIndex: 1, // Al-Baqarah 2
        juzVerses: juz,
      );

      expect(boundary, isNotNull);
      expect(boundary!.kind, ResumeBoundaryKind.juzEndAyahs);
      expect(boundary.remaining, 139); // up to Al-Baqarah 141
      expect(boundary.juzNo, 1);
    });

    test('a finished surah falls back to the remaining juz', () {
      final surah = _fatihah();
      final juz = [..._fatihah(), ..._baqarah(upTo: 141)];

      final boundary = computeSurahResumeBoundary(
        surahVerses: surah,
        verseIndex: 6, // Al-Fatihah 7
        juzVerses: juz,
      );

      expect(boundary, isNotNull);
      expect(boundary!.kind, ResumeBoundaryKind.juzEndAyahs);
      expect(boundary.remaining, 141);
      expect(boundary.juzNo, 1);
    });

    test('returns null when the position cannot be found', () {
      expect(
        computeSurahResumeBoundary(
          surahVerses: _fatihah(),
          verseIndex: 99,
          juzVerses: _fatihah(),
        ),
        isNull,
      );
    });
  });

  group('computeJuzResumeBoundary', () {
    test('counts ayahs to the end of the juz', () {
      final juz = [
        _verse(78, 1, page: 582, juz: 30),
        _verse(78, 2, page: 582, juz: 30),
        _verse(78, 3, page: 582, juz: 30),
      ];

      final boundary = computeJuzResumeBoundary(
        juzVerses: juz,
        surahId: 78,
        ayahNo: 1,
      );

      expect(boundary, isNotNull);
      expect(boundary!.kind, ResumeBoundaryKind.juzEndAyahs);
      expect(boundary.remaining, 2);
      expect(boundary.juzNo, 30);
    });
  });

  group('computePageResumeBoundary', () {
    test('mid-juz page reports remaining pages', () {
      final juz = [
        _verse(1, 1, page: 1, juz: 1),
        _verse(2, 141, page: 21, juz: 1),
      ];

      final boundary = computePageResumeBoundary(pageNo: 19, juzVerses: juz);

      expect(boundary, isNotNull);
      expect(boundary!.kind, ResumeBoundaryKind.juzEndPages);
      expect(boundary.remaining, 2);
      expect(boundary.juzNo, 1);
    });

    test('the last page of a juz has no hint', () {
      final juz = [
        _verse(1, 1, page: 1, juz: 1),
        _verse(2, 141, page: 21, juz: 1),
      ];

      expect(
        computePageResumeBoundary(pageNo: 21, juzVerses: juz),
        isNull,
      );
    });

    test('empty juz verses have no hint', () {
      expect(
        computePageResumeBoundary(pageNo: 1, juzVerses: const []),
        isNull,
      );
    });
  });
}
