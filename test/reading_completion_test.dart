import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/reading/reading_completion.dart';

LastReadPosition _lastRead({
  required String type,
  required int id,
  int? ayahNo,
  int? surahId,
}) {
  return LastReadPosition(
    type: type,
    id: id,
    ayahNo: ayahNo,
    surahId: surahId,
    timestamp: DateTime.utc(2026, 10, 31),
  );
}

LastReadProgress _progress({
  required String scope,
  required int current,
  required int total,
}) {
  return LastReadProgress(
    fraction: current / total,
    scope: scope,
    current: current,
    total: total,
  );
}

Verse _verse(int surahId, int ayahNo, {int page = 582, int juz = 30}) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: page,
    juz: juz,
    arabic: 'test',
  );
}

void main() {
  group('surah completion', () {
    test('Al-Mulk 67:30 continues at Al-Qalam 68:1', () {
      final completion = resolveSurahCompletion(
        lastRead: _lastRead(type: 'surah', id: 67, ayahNo: 30),
        progress: _progress(scope: 'surah', current: 30, total: 30),
      );

      expect(completion, isNotNull);
      expect(completion!.khatam, isFalse);
      expect(completion.finishedSurahId, 67);
      expect(completion.nextSurahId, 68);
      expect(completion.nextAyahNo, 1);

      final target = nextReadTarget(completion);
      expect(target.source, isA<SurahSource>());
      expect((target.source! as SurahSource).surahId, 68);
      expect(target.targetAyahNo, 1);
      expect(target.pageNo, isNull);
    });

    test('a mid-surah position is not completed', () {
      expect(
        resolveSurahCompletion(
          lastRead: _lastRead(type: 'surah', id: 67, ayahNo: 15),
          progress: _progress(scope: 'surah', current: 15, total: 30),
        ),
        isNull,
      );
    });

    test('114:6 is khatam and restarts at Al-Fatihah 1:1', () {
      final completion = resolveSurahCompletion(
        lastRead: _lastRead(type: 'surah', id: 114, ayahNo: 6),
        progress: _progress(scope: 'surah', current: 6, total: 6),
      );

      expect(completion, isNotNull);
      expect(completion!.khatam, isTrue);
      expect(completion.nextSurahId, 1);
      expect(completion.nextAyahNo, 1);

      final target = nextReadTarget(completion);
      expect((target.source! as SurahSource).surahId, 1);
      expect(target.targetAyahNo, 1);
    });
  });

  group('juz completion', () {
    test('Juz 29 end continues at the first verse of Juz 30', () {
      final completion = resolveJuzCompletion(
        lastRead: _lastRead(type: 'juz', id: 29, ayahNo: 45, surahId: 77),
        progress: _progress(scope: 'juz', current: 431, total: 431),
        nextJuzFirstVerse: _verse(78, 1, page: 582, juz: 30),
      );

      expect(completion, isNotNull);
      expect(completion!.khatam, isFalse);
      expect(completion.finishedJuzNo, 29);
      expect(completion.nextJuzNo, 30);
      expect(completion.nextSurahId, 78);
      expect(completion.nextAyahNo, 1);

      final target = nextReadTarget(completion);
      expect(target.source, isA<JuzSource>());
      expect((target.source! as JuzSource).juzNo, 30);
      expect(target.targetSurahId, 78);
      expect(target.targetAyahNo, 1);
    });

    test('Juz 30 end is khatam', () {
      final completion = resolveJuzCompletion(
        lastRead: _lastRead(type: 'juz', id: 30, ayahNo: 6, surahId: 114),
        progress: _progress(scope: 'juz', current: 564, total: 564),
        nextJuzFirstVerse: null,
      );

      expect(completion, isNotNull);
      expect(completion!.khatam, isTrue);
      expect(completion.nextSurahId, 1);
      expect(completion.nextAyahNo, 1);

      final target = nextReadTarget(completion);
      expect(target.source, isA<SurahSource>());
      expect((target.source! as SurahSource).surahId, 1);
      expect(target.targetAyahNo, 1);
    });

    test('a mid-juz position is not completed', () {
      expect(
        resolveJuzCompletion(
          lastRead: _lastRead(type: 'juz', id: 29, ayahNo: 10, surahId: 77),
          progress: _progress(scope: 'juz', current: 10, total: 431),
          nextJuzFirstVerse: _verse(78, 1),
        ),
        isNull,
      );
    });
  });

  group('mushaf completion', () {
    test('page 21 at the end of Juz 1 continues on page 22', () {
      final completion = resolvePageCompletion(
        lastRead: _lastRead(type: 'page', id: 21),
        location: const LastReadLocation(
          type: 'page',
          pageNo: 21,
          juzNo: 1,
          juzStartPage: 1,
          juzEndPage: 21,
        ),
      );

      expect(completion, isNotNull);
      expect(completion!.khatam, isFalse);
      expect(completion.finishedJuzNo, 1);
      expect(completion.nextPageNo, 22);

      final target = nextReadTarget(completion);
      expect(target.pageNo, 22);
      expect(target.source, isNull);
    });

    test('page 604 is khatam and restarts at page 1', () {
      final completion = resolvePageCompletion(
        lastRead: _lastRead(type: 'page', id: 604),
        location: const LastReadLocation(
          type: 'page',
          pageNo: 604,
          juzNo: 30,
          juzStartPage: 582,
          juzEndPage: 604,
        ),
      );

      expect(completion, isNotNull);
      expect(completion!.khatam, isTrue);
      expect(completion.nextPageNo, 1);

      final target = nextReadTarget(completion);
      expect(target.pageNo, 1);
    });

    test('a mid-juz page is not completed', () {
      expect(
        resolvePageCompletion(
          lastRead: _lastRead(type: 'page', id: 20),
          location: const LastReadLocation(
            type: 'page',
            pageNo: 20,
            juzNo: 1,
            juzStartPage: 1,
            juzEndPage: 21,
          ),
        ),
        isNull,
      );
    });
  });
}
