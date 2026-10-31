import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/reading/continue_card_view.dart';

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
    test('floors, keeps 1% once read, and only 100% when complete', () {
      expect(continueProgressPercent(null), 0);
      expect(continueProgressPercent(0), 0);
      expect(continueProgressPercent(1 / 604), 1);
      expect(continueProgressPercent(43 / 564), 7);
      expect(continueProgressPercent(2 / 7), 28);
      expect(continueProgressPercent(0.999), 99);
      expect(continueProgressPercent(1), 100);
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
}
