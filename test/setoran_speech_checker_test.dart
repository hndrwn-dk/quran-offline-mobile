import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/audio/phoneme_checker.dart';
import 'package:quran_offline/core/audio/setoran_speech_checker.dart';
import 'package:quran_offline/core/database/database.dart';

Verse _verse({
  required String arabic,
  String? translit,
  String? translitTj,
}) {
  return Verse(
    surahId: 114,
    ayahNo: 1,
    page: 604,
    juz: 30,
    arabic: arabic,
    tajweed: null,
    translit: translit,
    translitTj: translitTj,
    trEn: null,
    trId: null,
    trZh: null,
    trJa: null,
  );
}

void main() {
  test('matches normalized Arabic transcript for An-Nas ayah 1', () {
    const verse = Verse(
      surahId: 114,
      ayahNo: 1,
      page: 604,
      juz: 30,
      arabic: ' قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
      tajweed: null,
      translit: 'qul aʿūdhu birabbi l-nāsi',
      translitTj: "qul a'uwdhu birabbi nnnas",
      trEn: null,
      trId: null,
      trZh: null,
      trJa: null,
    );

    final result = SetoranSpeechChecker.check(
      transcript: 'قل اعوذ برب الناس',
      verse: verse,
    );

    expect(result.verdict, SetoranSpeechVerdict.correct);
    expect(result.score, greaterThan(0.7));
  });

  test('marks clearly wrong transcript as incorrect', () {
    final result = SetoranSpeechChecker.check(
      transcript: 'بسم الله الرحمن الرحيم',
      verse: _verse(
        arabic: 'مَلِكِ ٱلنَّاسِ',
        translit: 'maliki l-nāsi',
        translitTj: 'maliki nnnas',
      ),
    );

    expect(result.verdict, SetoranSpeechVerdict.incorrect);
  });

  test('empty transcript is uncertain', () {
    final result = SetoranSpeechChecker.check(
      transcript: ' ',
      verse: _verse(arabic: 'إِلَـٰهِ ٱلنَّاسِ'),
    );

    expect(result.verdict, SetoranSpeechVerdict.uncertain);
    expect(result.score, 0);
  });

  test('english STT garbage is uncertain not incorrect', () {
    final result = SetoranSpeechChecker.check(
      transcript: 'good long movie Romina',
      verse: _verse(
        arabic: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
        translitTj: "qul a'uwdhu birabbi nnnas",
      ),
    );

    expect(result.verdict, SetoranSpeechVerdict.uncertain);
  });

  test('latin transcript can match transliteration reference', () {
    final result = SetoranSpeechChecker.check(
      transcript: 'maliki nnas',
      verse: _verse(
        arabic: 'مَلِكِ ٱلنَّاسِ',
        translitTj: 'maliki nnnas',
      ),
    );

    expect(result.verdict, SetoranSpeechVerdict.correct);
  });

  group('PhonemeChecker integration with SetoranSpeechChecker', () {
    test('phoneme hints run without conflicting with speech verdict', () {
      const transcript = 'ملك الناس';
      const translitTj = 'maliki nnnas';
      const tajweed =
          'مَلِكِ <tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed><tajweed class=ghunnah>نّ</tajweed>';
      const arabic = 'مَلِكِ ٱلنَّاسِ';

      final speechResult = SetoranSpeechChecker.check(
        transcript: transcript,
        verse: _verse(
          arabic: arabic,
          translitTj: translitTj,
        ),
      );
      final phonemeResult = PhonemeChecker.check(
        transcript: transcript,
        translitTj: translitTj,
        tajweedHtml: tajweed,
        arabic: arabic,
      );

      expect(speechResult.verdict, isNot(SetoranSpeechVerdict.incorrect));
      expect(phonemeResult, isNotNull);
    });
  });
}
