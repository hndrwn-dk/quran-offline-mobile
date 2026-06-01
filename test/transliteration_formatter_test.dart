import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/transliteration_formatter.dart';

void main() {
  group('TransliterationFormatter', () {
    group('toReadable', () {
      test('1:1 bis''mi l-lahi -> bismi llahi l-raḥmāni l-raḥīm (waqf)', () {
        const tl = "bis'mi l-lahi l-raḥmāni l-raḥīmi";
        final out = TransliterationFormatter.toReadable(tl);
        expect(out, 'bismi llahi l-raḥmāni l-raḥīm');
      });

      test('1:6 ih''dinā l-ṣirāṭa l-mus''taqīma -> ihdinā l-ṣirāṭa l-mustaqīm (waqf)', () {
        const tl = "ih'dinā l-ṣirāṭa l-mus'taqīma";
        final out = TransliterationFormatter.toReadable(tl);
        expect(out, 'ihdinā l-ṣirāṭa l-mustaqīm');
      });

      test('R1: removes syllable apostrophe in multiple words', () {
        expect(
          TransliterationFormatter.toReadable("bis'mi l-lahi l-raḥmāni"),
          'bismi llahi l-raḥmān',
        );
        expect(
          TransliterationFormatter.toReadable("anʿamta"),
          'anʿamt',
        );
      });

      test('R2: collapses multiple spaces and trims', () {
        expect(
          TransliterationFormatter.toReadable('  al-ḥamdu   lillahi  '),
          'al-ḥamdu lillah',
        );
      });

      test('R3: l-l -> ll (article hyphen)', () {
        expect(
          TransliterationFormatter.toReadable('l-lahi'),
          'llah',
        );
        expect(
          TransliterationFormatter.toReadable('l-raḥmāni l-raḥīmi'),
          'l-raḥmāni l-raḥīm',
        );
      });

      test('R4: waqf - drop final short vowel', () {
        expect(
          TransliterationFormatter.toReadable('l-dīni'),
          'l-dīn',
        );
        expect(
          TransliterationFormatter.toReadable("al-ḥamdu lillahi rabbi l-'ālamīna"),
          "al-ḥamdu lillahi rabbi l-'ālamīn",
        );
      });

      test('preserves diacritics (ā ī ū ṣ ḥ ʿ)', () {
        const tl = "ṣirāṭa alladhīna anʿamta ʿalayhim";
        final out = TransliterationFormatter.toReadable(tl);
        expect(out, contains('ṣ'));
        expect(out, contains('ā'));
        expect(out, contains('ī'));
        expect(out, contains('ʿ'));
      });

      test('empty string returns empty', () {
        expect(TransliterationFormatter.toReadable(''), '');
      });
    });

    group('displayTransliteration', () {
      test('original style returns tlRaw as-is', () {
        const tl = "bis'mi l-lahi";
        final out = TransliterationFormatter.displayTransliteration(
          tlRaw: tl,
          style: TransliterationStyle.original,
        );
        expect(out, tl);
      });

      test('readable style returns toReadable(tlRaw)', () {
        const tl = "bis'mi l-lahi";
        final out = TransliterationFormatter.displayTransliteration(
          tlRaw: tl,
          style: TransliterationStyle.readable,
        );
        expect(out, 'bismi llah');
      });

      test('readable style applies waqf on last vowel', () {
        const tl = 'l-raḥīmi';
        final out = TransliterationFormatter.displayTransliteration(
          tlRaw: tl,
          style: TransliterationStyle.readable,
        );
        expect(out, 'l-raḥīm');
      });

      test('null or empty tlRaw returns empty string', () {
        expect(
          TransliterationFormatter.displayTransliteration(
            tlRaw: null,
            style: TransliterationStyle.readable,
          ),
          '',
        );
        expect(
          TransliterationFormatter.displayTransliteration(
            tlRaw: '',
            style: TransliterationStyle.readable,
          ),
          '',
        );
      });
    });
  });
}
