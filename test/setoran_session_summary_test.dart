import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/audio/phoneme_checker.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/features/hafalan/models/setoran_ayah_fade_state.dart';
import 'package:quran_offline/features/hafalan/models/setoran_session_summary.dart';

Verse _verse(int ayahNo) {
  return Verse(
    surahId: 114,
    ayahNo: ayahNo,
    page: 604,
    juz: 30,
    arabic: 'test',
    tajweed: null,
    translit: null,
    translitTj: null,
    trEn: null,
    trId: null,
    trZh: null,
    trJa: null,
  );
}

void main() {
  group('SetoranSessionSummaryBuilder', () {
    test('counts revealed and error ayahs', () {
      final summary = SetoranSessionSummaryBuilder.build(
        verses: [_verse(1), _verse(2), _verse(3)],
        states: [
          SetoranAyahFadeState.revealed,
          SetoranAyahFadeState.error,
          SetoranAyahFadeState.ghost,
        ],
        phonemeByAyah: const {},
        speechScoreByAyah: const {},
        lang: 'id',
      );

      expect(summary.revealedCount, 1);
      expect(summary.errorCount, 1);
      expect(summary.ghostCount, 1);
      expect(summary.reviewAyahIndices, [1]);
      expect(summary.allRevealed, isFalse);
    });

    test('aggregates tajwid notes and averages', () {
      const tajweed =
          '<tajweed class=laam_shamsiyah>ل</tajweed><tajweed class=ghunnah>نّ</tajweed>';
      final phoneme = PhonemeChecker.check(
        transcript: 'alrahmani alrahim',
        translitTj: 'arrahmani rrahiym',
        tajweedHtml: tajweed,
        arabic: 'الرحمن الرحيم',
        language: 'id',
      );

      final summary = SetoranSessionSummaryBuilder.build(
        verses: [_verse(1)],
        states: [SetoranAyahFadeState.revealed],
        phonemeByAyah: {0: phoneme},
        speechScoreByAyah: {0: 0.92},
        lang: 'id',
      );

      expect(summary.avgTajwidScore, phoneme.phonemeTajweedScore);
      expect(summary.avgTextScore, 92);
      expect(summary.topTajwidNotes, isNotEmpty);
      expect(summary.needsImprovement, isTrue);
    });

    test('flags weak tajwid on revealed ayah for review', () {
      final phoneme = PhonemeChecker.check(
        transcript: 'maliki alnas',
        translitTj: 'maliki nnnas',
        tajweedHtml:
            '<tajweed class=laam_shamsiyah>ل</tajweed><tajweed class=ghunnah>نّ</tajweed>',
        arabic: 'ملك الناس',
        language: 'id',
      );

      final summary = SetoranSessionSummaryBuilder.build(
        verses: [_verse(2)],
        states: [SetoranAyahFadeState.revealed],
        phonemeByAyah: {0: phoneme},
        speechScoreByAyah: {0: 0.95},
        lang: 'id',
      );

      expect(summary.errorCount, 0);
      expect(summary.reviewAyahIndices, [0]);
      expect(summary.topTajwidNotes.length, lessThanOrEqualTo(3));
    });

    test('all revealed with clean phoneme is ready', () {
      final phoneme = PhonemeChecker.check(
        transcript: 'maliki nnnas',
        translitTj: 'maliki nnnas',
        tajweedHtml:
            '<tajweed class=laam_shamsiyah>ل</tajweed><tajweed class=ghunnah>نّ</tajweed>',
        arabic: 'ملك الناس',
        language: 'id',
      );

      final summary = SetoranSessionSummaryBuilder.build(
        verses: [_verse(1), _verse(2)],
        states: [
          SetoranAyahFadeState.revealed,
          SetoranAyahFadeState.revealed,
        ],
        phonemeByAyah: {0: phoneme, 1: phoneme},
        speechScoreByAyah: {0: 0.9, 1: 0.88},
        lang: 'id',
      );

      expect(summary.allRevealed, isTrue);
      expect(summary.needsImprovement, isFalse);
    });
  });
}
