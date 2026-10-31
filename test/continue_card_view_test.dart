import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/reading/continue_card_view.dart';
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

void main() {
  group('continueProgressPercent', () {
    test('floors, keeps 1% once read, and never shows 100%', () {
      expect(continueProgressPercent(null), 0);
      expect(continueProgressPercent(0), 0);
      expect(continueProgressPercent(1 / 604), 1);
      expect(continueProgressPercent(43 / 564), 7);
      expect(continueProgressPercent(2 / 7), 28);
      expect(continueProgressPercent(0.999), 99);
      expect(continueProgressPercent(1), 99);
    });
  });

  test('An-Naba 78:6 in surah mode uses the surah total', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'surah', id: 78, ayahNo: 6),
      location: const LastReadLocation(
        type: 'surah',
        surahId: 78,
        ayahNo: 6,
        juzNo: 30,
      ),
      progress: _progress(scope: 'surah', current: 6, total: 40),
      surahName: 'An-Naba',
    );

    expect(view.title, 'An-Naba');
    expect(view.detail, 'Ayat 6 dari 40 · Juz 30');
    expect(view.percent, 15);
  });

  test('An-Naba 78:6 in juz mode separates ayah and juz index', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'juz', id: 30, ayahNo: 6, surahId: 78),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 78,
        ayahNo: 6,
        juzNo: 30,
      ),
      progress: _progress(scope: 'juz', current: 6, total: 564),
      surahName: 'An-Naba',
    );

    expect(view.title, 'Juz 30 (Juz Amma)');
    expect(view.detail, 'An-Naba ayat 6 · 6 dari 564 ayat');
    expect(view.percent, 1);
  });

  test('An-Nazi\'at 79:3 in juz mode uses the juz index', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'juz', id: 30, ayahNo: 3, surahId: 79),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 79,
        ayahNo: 3,
        juzNo: 30,
      ),
      progress: _progress(scope: 'juz', current: 43, total: 564),
      surahName: 'An-Nazi\'at',
    );

    expect(view.title, 'Juz 30 (Juz Amma)');
    expect(view.detail, 'An-Nazi\'at ayat 3 · 43 dari 564 ayat');
    expect(view.percent, 7);
  });

  test('Al-Baqarah 2:255 in Juz 3', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'juz', id: 3, ayahNo: 255, surahId: 2),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 2,
        ayahNo: 255,
        juzNo: 3,
      ),
      progress: _progress(scope: 'juz', current: 3, total: 126),
      surahName: 'Al-Baqarah',
    );

    expect(view.title, 'Juz 3');
    expect(view.detail, 'Al-Baqarah ayat 255 · 3 dari 126 ayat');
    expect(view.percent, 2);
  });

  test('mushaf page 582 is a page in Juz 30', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'page', id: 582, surahId: 78),
      location: const LastReadLocation(
        type: 'page',
        surahId: 78,
        pageNo: 582,
        juzNo: 30,
        juzStartPage: 582,
        juzEndPage: 604,
      ),
      progress: null,
      surahName: 'An-Naba',
    );

    expect(view.title, 'Halaman 582');
    expect(view.detail, 'An-Naba · Juz 30 · hal. 1 dari 23');
    expect(view.percent, 4);
    expect(view.fraction, closeTo(1 / 23, 1e-9));
  });

  test('English copy keeps the unit words', () {
    final juz = buildContinueCardView(
      language: 'en',
      lastRead: _lastRead(type: 'juz', id: 30, ayahNo: 6, surahId: 78),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 78,
        ayahNo: 6,
        juzNo: 30,
      ),
      progress: _progress(scope: 'juz', current: 6, total: 564),
      surahName: 'An-Naba',
    );
    final page = buildContinueCardView(
      language: 'en',
      lastRead: _lastRead(type: 'page', id: 582, surahId: 78),
      location: const LastReadLocation(
        type: 'page',
        surahId: 78,
        pageNo: 582,
        juzNo: 30,
        juzStartPage: 582,
        juzEndPage: 604,
      ),
      progress: null,
      surahName: 'An-Naba',
    );

    expect(juz.detail, 'An-Naba ayah 6 · 6 of 564 ayahs');
    expect(page.title, 'Page 582');
    expect(page.detail, 'An-Naba · Juz 30 · p. 1 of 23');
  });

  test('completed surah points at the next surah', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'surah', id: 67, ayahNo: 30),
      location: const LastReadLocation(
        type: 'surah',
        surahId: 67,
        ayahNo: 30,
        juzNo: 29,
      ),
      progress: null,
      surahName: 'Al-Mulk',
      completion: const ReadingCompletion(
        kind: 'surah',
        khatam: false,
        finishedSurahId: 67,
        nextSurahId: 68,
        nextAyahNo: 1,
      ),
      nextSurahName: 'Al-Qalam',
    );

    expect(view.completed, isTrue);
    expect(view.title, 'Alhamdulillah, Al-Mulk selesai');
    expect(view.detail, 'Lanjut ke Al-Qalam');
    expect(view.percent, isNull);
  });

  test('completed juz points at the next juz', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'juz', id: 29, ayahNo: 45, surahId: 77),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 77,
        ayahNo: 45,
        juzNo: 29,
      ),
      progress: null,
      surahName: 'Al-Mursalat',
      completion: const ReadingCompletion(
        kind: 'juz',
        khatam: false,
        finishedJuzNo: 29,
        nextJuzNo: 30,
        nextSurahId: 78,
        nextAyahNo: 1,
      ),
    );

    expect(view.completed, isTrue);
    expect(view.title, 'Alhamdulillah, Juz 29 selesai');
    expect(view.detail, 'Lanjut ke Juz 30');
  });

  test('completed mushaf page points at the next page', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'page', id: 21),
      location: const LastReadLocation(
        type: 'page',
        pageNo: 21,
        juzNo: 1,
        juzStartPage: 1,
        juzEndPage: 21,
      ),
      progress: null,
      surahName: 'Al-Baqarah',
      completion: const ReadingCompletion(
        kind: 'page',
        khatam: false,
        finishedJuzNo: 1,
        nextPageNo: 22,
      ),
    );

    expect(view.completed, isTrue);
    expect(view.title, 'Alhamdulillah, Juz 1 selesai');
    expect(view.detail, 'Lanjut ke Halaman 22');
  });

  test('khatam uses the khatam copy', () {
    final view = buildContinueCardView(
      language: 'id',
      lastRead: _lastRead(type: 'surah', id: 114, ayahNo: 6),
      location: const LastReadLocation(
        type: 'surah',
        surahId: 114,
        ayahNo: 6,
        juzNo: 30,
      ),
      progress: null,
      surahName: 'An-Nas',
      completion: const ReadingCompletion(
        kind: 'surah',
        khatam: true,
        finishedSurahId: 114,
        nextSurahId: 1,
        nextAyahNo: 1,
      ),
    );

    expect(view.completed, isTrue);
    expect(view.khatam, isTrue);
    expect(view.title, 'Alhamdulillah, khatam Al-Qur\'an');
    expect(view.detail, 'Mulai lagi dari Al-Fatihah');
  });
}
