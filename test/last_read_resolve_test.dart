import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/last_read_resolve.dart';

Verse _verse(int surahId, int ayahNo) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: 1,
    juz: 1,
    arabic: 'test',
  );
}

/// Juz 1 starts Al-Fatiha 1-7 then Al-Baqarah.
List<Verse> _juz1() => [
      _verse(1, 1),
      _verse(1, 2),
      _verse(1, 3),
      _verse(1, 4),
      _verse(1, 5),
      _verse(1, 6),
      _verse(1, 7),
      _verse(2, 1),
      _verse(2, 2),
      _verse(2, 3),
      _verse(2, 4),
      _verse(2, 5),
    ];

void main() {
  group('buildLastReadPosition', () {
    test('persists visible surahId for JuzSource', () {
      final pos = buildLastReadPosition(
        const JuzSource(1),
        ayahNo: 5,
        surahId: 2,
        timestamp: DateTime.utc(2026, 8, 14),
      );
      expect(pos.type, 'juz');
      expect(pos.id, 1);
      expect(pos.ayahNo, 5);
      expect(pos.surahId, 2);
    });

    test('stores juzNo in surahId field for SurahInJuzSource', () {
      final pos = buildLastReadPosition(
        const SurahInJuzSource(1, 2),
        ayahNo: 5,
        timestamp: DateTime.utc(2026, 8, 14),
      );
      expect(pos.type, 'surah_in_juz');
      expect(pos.id, 2);
      expect(pos.ayahNo, 5);
      expect(pos.surahId, 1);
    });
  });

  group('indexOfTargetVerse', () {
    test('juz resume requires surah+ayah and lands on Al-Baqarah 5', () {
      final index = indexOfTargetVerse(
        _juz1(),
        ayahNo: 5,
        surahId: 2,
        requireSurahId: true,
      );
      expect(index, 11);
      expect(_juz1()[index!].surahId, 2);
      expect(_juz1()[index].ayahNo, 5);
    });

    test('juz resume without surahId does not fall back to first ayah 5', () {
      final index = indexOfTargetVerse(
        _juz1(),
        ayahNo: 5,
        surahId: null,
        requireSurahId: true,
      );
      expect(index, isNull);
    });

    test('surah list still matches ayah-only when surahId omitted', () {
      final surah = [_verse(2, 1), _verse(2, 5), _verse(2, 6)];
      expect(
        indexOfTargetVerse(surah, ayahNo: 5),
        1,
      );
    });
  });

  group('resolveJuzSurahAyah', () {
    test('returns Baqarah 5 when surahId is stored', () {
      final lastRead = LastReadPosition(
        type: 'juz',
        id: 1,
        ayahNo: 5,
        surahId: 2,
        timestamp: DateTime.utc(2026, 8, 14),
      );
      final coords = resolveJuzSurahAyah(_juz1(), lastRead);
      expect(coords?.surahId, 2);
      expect(coords?.ayahNo, 5);
    });

    test('legacy juz ayah without surahId starts at first verse not Fatihah 5', () {
      final lastRead = LastReadPosition(
        type: 'juz',
        id: 1,
        ayahNo: 5,
        surahId: null,
        timestamp: DateTime.utc(2026, 8, 14),
      );
      final coords = resolveJuzSurahAyah(_juz1(), lastRead);
      expect(coords?.surahId, 1);
      expect(coords?.ayahNo, 1);
    });
  });

  group('computeLastReadProgress', () {
    test('juz with surahId uses Baqarah 5 index not Fatihah 5', () {
      final lastRead = LastReadPosition(
        type: 'juz',
        id: 1,
        ayahNo: 5,
        surahId: 2,
        timestamp: DateTime.utc(2026, 8, 14),
      );
      final progress = computeLastReadProgress(
        lastRead: lastRead,
        juzVerses: _juz1(),
      );
      expect(progress, isNotNull);
      expect(progress!.scope, 'juz');
      expect(progress.current, 12);
      expect(progress.total, 12);
    });

    test('surah_in_juz uses surah-scoped progress instead of null', () {
      final lastRead = LastReadPosition(
        type: 'surah_in_juz',
        id: 2,
        ayahNo: 5,
        surahId: 1,
        timestamp: DateTime.utc(2026, 8, 14),
      );
      final progress = computeLastReadProgress(
        lastRead: lastRead,
        surahAyahCount: 286,
      );
      expect(progress, isNotNull);
      expect(progress!.scope, 'surah');
      expect(progress.current, 5);
      expect(progress.total, 286);
    });
  });

  group('lastReadCardHandlesType', () {
    test('surah_in_juz is a supported continue-card type', () {
      expect(lastReadCardHandlesType('surah'), isTrue);
      expect(lastReadCardHandlesType('juz'), isTrue);
      expect(lastReadCardHandlesType('page'), isTrue);
      expect(lastReadCardHandlesType('surah_in_juz'), isTrue);
      expect(lastReadCardHandlesType('unknown'), isFalse);
    });
  });

  group('resolveSurahAyahFromLastRead juz list', () {
    test('widget coords follow stored surahId', () async {
      final lastRead = LastReadPosition(
        type: 'juz',
        id: 1,
        ayahNo: 5,
        surahId: 2,
        timestamp: DateTime.utc(2026, 8, 14),
      );
      final coords = resolveJuzSurahAyah(_juz1(), lastRead);
      expect(coords, isNotNull);
      expect(coords!.surahId, 2);
      expect(coords.ayahNo, 5);
    });
  });
}
