import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/audio/phoneme_checker.dart';
import 'package:quran_offline/core/quran/tajweed_rule_parser.dart';

void main() {
  const translitTj114_2 = 'maliki nnnas';
  const tajweed114_2 =
      'مَلِكِ <tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed><tajweed class=ghunnah>نّ</tajweed><tajweed class=madda_permissible>َا</tajweed>سِ';
  const arabic114_2 = 'مَلِكِ ٱلنَّاسِ';

  group('PhonemeChecker — An-Nas 114:2', () {
    test('matching tl_tj transcript has no laam violations', () {
      final result = PhonemeChecker.check(
        transcript: 'maliki nnnas',
        translitTj: translitTj114_2,
        tajweedHtml: tajweed114_2,
        arabic: arabic114_2,
      );

      expect(result.laamShamsViolations, isEmpty);
      expect(result.phonemeTajweedScore, greaterThanOrEqualTo(85));
    });

    test('alnas instead of nnnas may flag laam or ghunnah', () {
      final result = PhonemeChecker.check(
        transcript: 'maliki alnas',
        translitTj: translitTj114_2,
        tajweedHtml: tajweed114_2,
        arabic: arabic114_2,
      );

      expect(
        result.laamShamsViolations.isNotEmpty ||
            result.ghunnahViolations.isNotEmpty,
        isTrue,
      );
    });

    test('Arabic script transcript produces a result', () {
      final result = PhonemeChecker.check(
        transcript: 'ملك الناس',
        translitTj: translitTj114_2,
        tajweedHtml: tajweed114_2,
        arabic: arabic114_2,
      );

      expect(result.wordScores, isNotEmpty);
    });
  });

  const translitTj1_3 = 'arrahmani rrahiym';
  const tajweed1_3 =
      'ٱ<tajweed class=laam_shamsiyah>ل</tajweed>رَّحْمَ<tajweed class=madda_normal>ـٰ</tajweed>نِ <tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed>رَّح<tajweed class=madda_permissible>ِي</tajweed>مِ';
  const arabic1_3 = 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  group('PhonemeChecker — Al-Fatihah 1:3', () {
    test('correct pronunciation scores high', () {
      final result = PhonemeChecker.check(
        transcript: 'arrahmani rrahiym',
        translitTj: translitTj1_3,
        tajweedHtml: tajweed1_3,
        arabic: arabic1_3,
      );

      expect(result.phonemeTajweedScore, greaterThanOrEqualTo(80));
    });

    test('alrahman triggers laam syamsiyah violation', () {
      final result = PhonemeChecker.check(
        transcript: 'alrahmani alrahim',
        translitTj: translitTj1_3,
        tajweedHtml: tajweed1_3,
        arabic: arabic1_3,
      );

      expect(result.laamShamsViolations, isNotEmpty);
    });
  });

  group('TajweedRuleParser', () {
    test('parses laam_shamsiyah', () {
      const tj = '<tajweed class=laam_shamsiyah>ل</tajweed>نَّاسِ';
      final map = TajweedRuleParser.parse(tj);
      expect(map.laamSpans, hasLength(1));
      expect(map.laamSpans.first.arabicText, equals('ل'));
    });

    test('parses ghunnah', () {
      const tj = '<tajweed class=ghunnah>نّ</tajweed>';
      final map = TajweedRuleParser.parse(tj);
      expect(map.ghunnahSpans, hasLength(1));
    });

    test('parses madda_necessary', () {
      const tj = 'ضّ<tajweed class=madda_necessary>َا</tajweed>ٓلّ';
      final map = TajweedRuleParser.parse(tj);
      expect(map.hasMadLazim, isTrue);
    });

    test('strips span end markers', () {
      const tj = 'text <span class=end>٢</span>';
      final map = TajweedRuleParser.parse(tj);
      expect(map.spans, isEmpty);
    });

    test('hintSpans deduplicates rules', () {
      const tj =
          '<tajweed class=laam_shamsiyah>ل</tajweed>'
          '<tajweed class=ghunnah>نّ</tajweed>'
          '<tajweed class=madda_normal>ـٰ</tajweed>';
      final map = TajweedRuleParser.parse(tj);
      expect(map.hintSpans(limit: 3), hasLength(3));
    });
  });
}
