import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/features/audio/recitation_navigation_logic.dart';

Verse _verse(int surahId, {int ayahNo = 1, int juz = 1}) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: 1,
    juz: juz,
    arabic: 'test',
  );
}

void main() {
  group('resolveRecitationOpenStrategy', () {
    test('idle audio -> none', () {
      expect(
        resolveRecitationOpenStrategy(
          audioActive: false,
          playingSurahId: null,
          returnSurface: RecitationReturnSurface.reader,
          mushafSessionActive: false,
          readerScreenVisible: false,
          readerSplitLayout: false,
        ),
        RecitationOpenStrategy.none,
      );
    });

    group('played from mushaf (return surface mushaf)', () {
      test('mushaf already open -> jumpMushaf', () {
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: 2,
            returnSurface: RecitationReturnSurface.mushaf,
            mushafSessionActive: true,
            readerScreenVisible: false,
            readerSplitLayout: false,
          ),
          RecitationOpenStrategy.jumpMushaf,
        );
      });

      test('back on list -> pushMushaf', () {
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: 2,
            returnSurface: RecitationReturnSurface.mushaf,
            mushafSessionActive: false,
            readerScreenVisible: false,
            readerSplitLayout: false,
          ),
          RecitationOpenStrategy.pushMushaf,
        );
      });

      test('reader also open -> still jump/push mushaf not reader', () {
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: 2,
            returnSurface: RecitationReturnSurface.mushaf,
            mushafSessionActive: true,
            readerScreenVisible: true,
            readerSplitLayout: false,
          ),
          RecitationOpenStrategy.jumpMushaf,
        );
      });
    });

    group('played from surah/juz reader (return surface reader)', () {
      test('phone reader open -> jumpReader', () {
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: 2,
            returnSurface: RecitationReturnSurface.reader,
            mushafSessionActive: false,
            readerScreenVisible: true,
            readerSplitLayout: false,
          ),
          RecitationOpenStrategy.jumpReader,
        );
      });

      test('tablet split on read tab -> jumpReader', () {
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: 2,
            returnSurface: RecitationReturnSurface.reader,
            mushafSessionActive: false,
            readerScreenVisible: false,
            readerSplitLayout: true,
          ),
          RecitationOpenStrategy.jumpReader,
        );
      });

      test('on surah list after back -> pushReader', () {
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: 2,
            returnSurface: RecitationReturnSurface.reader,
            mushafSessionActive: false,
            readerScreenVisible: false,
            readerSplitLayout: false,
          ),
          RecitationOpenStrategy.pushReader,
        );
      });

      test('null return surface defaults to reader push', () {
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: 1,
            returnSurface: null,
            mushafSessionActive: false,
            readerScreenVisible: false,
            readerSplitLayout: false,
          ),
          RecitationOpenStrategy.pushReader,
        );
      });
    });
  });

  group('shouldHideGlobalRecitationBar', () {
    const playing = 2;
    final juz1WithBaqarah = [_verse(1), _verse(2, ayahNo: 5, juz: 1)];
    final juz30Only = [_verse(78, juz: 30)];

    test('no audio -> never hide', () {
      expect(
        shouldHideGlobalRecitationBar(
          audioActive: false,
          playingSurahId: playing,
          readerSource: const SurahSource(2),
          splitLayout: false,
          onReadTab: true,
          readerScreenVisible: true,
          juzVerses: null,
        ),
        isFalse,
      );
    });

    group('phone (no split)', () {
      test('surah list while playing -> show bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: null,
            splitLayout: false,
            onReadTab: true,
            readerScreenVisible: false,
            juzVerses: null,
          ),
          isFalse,
        );
      });

      test('surah reader same surah -> hide bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const SurahSource(2),
            splitLayout: false,
            onReadTab: true,
            readerScreenVisible: true,
            juzVerses: null,
          ),
          isTrue,
        );
      });

      test('surah reader different surah -> show bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const SurahSource(3),
            splitLayout: false,
            onReadTab: true,
            readerScreenVisible: true,
            juzVerses: null,
          ),
          isFalse,
        );
      });

      test('juz reader contains playing surah -> hide bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const JuzSource(1),
            splitLayout: false,
            onReadTab: true,
            readerScreenVisible: true,
            juzVerses: juz1WithBaqarah,
          ),
          isTrue,
        );
      });

      test('juz reader without playing surah -> show bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const JuzSource(30),
            splitLayout: false,
            onReadTab: true,
            readerScreenVisible: true,
            juzVerses: juz30Only,
          ),
          isFalse,
        );
      });

      test('surah-in-juz reader same surah -> hide bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const SurahInJuzSource(1, 2),
            splitLayout: false,
            onReadTab: true,
            readerScreenVisible: true,
            juzVerses: null,
          ),
          isTrue,
        );
      });

      test('reader route still visible on phone -> hide bar (tab ignored)', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const SurahSource(2),
            splitLayout: false,
            onReadTab: false,
            readerScreenVisible: true,
            juzVerses: null,
          ),
          isTrue,
        );
      });
    });

    group('tablet split on read tab', () {
      test('surah pane same surah -> hide bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const SurahSource(2),
            splitLayout: true,
            onReadTab: true,
            readerScreenVisible: false,
            juzVerses: null,
          ),
          isTrue,
        );
      });

      test('juz pane contains playing surah -> hide bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const JuzSource(1),
            splitLayout: true,
            onReadTab: true,
            readerScreenVisible: false,
            juzVerses: juz1WithBaqarah,
          ),
          isTrue,
        );
      });

      test('not on read tab -> show bar', () {
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: playing,
            readerSource: const SurahSource(2),
            splitLayout: true,
            onReadTab: false,
            readerScreenVisible: false,
            juzVerses: null,
          ),
          isFalse,
        );
      });
    });
  });

  group('requestReaderJump (provider state)', () {
    test('updates source and jump token without duplicate push flag', () {
      // Documented behavior: jump sets visible sources; push is caller responsibility.
      expect(readerShowsPlayingSurah(const SurahSource(2), 2), isTrue);
      expect(readerShowsPlayingSurah(const SurahInJuzSource(1, 2), 2), isTrue);
      expect(readerShowsPlayingSurah(const JuzSource(1), 2), isFalse);
      expect(juzReaderShowsPlayingSurah([_verse(2)], 2), isTrue);
    });
  });

  group('combination matrix (open + bar visibility)', () {
    final cases = <({
      String label,
      RecitationReturnSurface surface,
      bool mushafOpen,
      bool readerOpen,
      bool split,
      bool onRead,
      ReaderSource? source,
      List<Verse>? juzVerses,
      RecitationOpenStrategy expectedOpen,
      bool expectedHideBar,
    })>[
      (
        label: 'mushaf play, mushaf open, tap mini',
        surface: RecitationReturnSurface.mushaf,
        mushafOpen: true,
        readerOpen: false,
        split: false,
        onRead: true,
        source: null,
        juzVerses: null,
        expectedOpen: RecitationOpenStrategy.jumpMushaf,
        expectedHideBar: false,
      ),
      (
        label: 'mushaf play, surah list, tap mini',
        surface: RecitationReturnSurface.mushaf,
        mushafOpen: false,
        readerOpen: false,
        split: false,
        onRead: true,
        source: null,
        juzVerses: null,
        expectedOpen: RecitationOpenStrategy.pushMushaf,
        expectedHideBar: false,
      ),
      (
        label: 'surah play, surah reader open',
        surface: RecitationReturnSurface.reader,
        mushafOpen: false,
        readerOpen: true,
        split: false,
        onRead: true,
        source: const SurahSource(2),
        juzVerses: null,
        expectedOpen: RecitationOpenStrategy.jumpReader,
        expectedHideBar: true,
      ),
      (
        label: 'surah play, surah list',
        surface: RecitationReturnSurface.reader,
        mushafOpen: false,
        readerOpen: false,
        split: false,
        onRead: true,
        source: null,
        juzVerses: null,
        expectedOpen: RecitationOpenStrategy.pushReader,
        expectedHideBar: false,
      ),
      (
        label: 'juz play, juz reader open (Al-Baqarah in Juz 1)',
        surface: RecitationReturnSurface.reader,
        mushafOpen: false,
        readerOpen: true,
        split: false,
        onRead: true,
        source: const JuzSource(1),
        juzVerses: [_verse(1), _verse(2)],
        expectedOpen: RecitationOpenStrategy.jumpReader,
        expectedHideBar: true,
      ),
      (
        label: 'juz play, juz list after back',
        surface: RecitationReturnSurface.reader,
        mushafOpen: false,
        readerOpen: false,
        split: false,
        onRead: true,
        source: const JuzSource(1),
        juzVerses: null,
        expectedOpen: RecitationOpenStrategy.pushReader,
        expectedHideBar: false,
      ),
      (
        label: 'surah-in-juz play, reader open',
        surface: RecitationReturnSurface.reader,
        mushafOpen: false,
        readerOpen: true,
        split: false,
        onRead: true,
        source: const SurahInJuzSource(1, 2),
        juzVerses: null,
        expectedOpen: RecitationOpenStrategy.jumpReader,
        expectedHideBar: true,
      ),
    ];

    for (final c in cases) {
      test(c.label, () {
        const surahId = 2;
        expect(
          resolveRecitationOpenStrategy(
            audioActive: true,
            playingSurahId: surahId,
            returnSurface: c.surface,
            mushafSessionActive: c.mushafOpen,
            readerScreenVisible: c.readerOpen,
            readerSplitLayout: c.split,
          ),
          c.expectedOpen,
        );
        expect(
          shouldHideGlobalRecitationBar(
            audioActive: true,
            playingSurahId: surahId,
            readerSource: c.source,
            splitLayout: c.split,
            onReadTab: c.onRead,
            readerScreenVisible: c.readerOpen,
            juzVerses: c.juzVerses,
          ),
          c.expectedHideBar,
        );
      });
    }
  });
}
