import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/home_widget_ayah_renderer.dart';
import 'package:quran_offline/core/widgets/home_widget_mapping.dart';
import 'package:quran_offline/core/widgets/home_widget_payload.dart';

void main() {
  group('flattenReflectionAyahs', () {
    test('expands ranges in reading order', () {
      final ayahs = flattenReflectionAyahs(const [
        DuaAyahRef(surah: 94, from: 5, to: 6),
        DuaAyahRef(surah: 2, from: 286, to: 286),
      ]);
      expect(ayahs, [
        (surah: 94, ayah: 5),
        (surah: 94, ayah: 6),
        (surah: 2, ayah: 286),
      ]);
    });
  });

  group('pickWidgetReflectionAyah', () {
    test('keeps the first ayah when it fits', () {
      final picked = pickWidgetReflectionAyah(
        const [DuaAyahRef(surah: 94, from: 5, to: 8)],
        (_, __) => 40,
      )!;
      expect((picked.surah, picked.ayah), (94, 5));
      expect(picked.index, 1);
      expect(picked.total, 4);
    });

    test('falls back to the shortest ayah when the first is too long', () {
      final lengths = {155: 400, 156: 90, 157: 120};
      final picked = pickWidgetReflectionAyah(
        const [DuaAyahRef(surah: 2, from: 155, to: 157)],
        (_, a) => lengths[a],
      )!;
      expect(picked.ayah, 156);
      expect(picked.index, 2);
      expect(picked.total, 3);
    });

    test('keeps the first ayah when lengths are unknown', () {
      final picked = pickWidgetReflectionAyah(
        const [DuaAyahRef(surah: 103, from: 1, to: 3)],
        (_, __) => null,
      )!;
      expect(picked.ayah, 1);
    });

    test('returns null without refs', () {
      expect(pickWidgetReflectionAyah(const [], (_, __) => 1), isNull);
    });
  });

  group('continue mapping', () {
    test('page percent through the 604-page Mushaf', () {
      expect(widgetQuranPagePercent(1), 1);
      expect(widgetQuranPagePercent(302), 50);
      expect(widgetQuranPagePercent(604), 100);
      expect(widgetQuranPagePercent(0), 0);
    });

    test('meta joins page and juz', () {
      expect(
        widgetContinueMeta(pageLabel: 'Hal. 297', juzLabel: 'Juz 15'),
        'Hal. 297 · Juz 15',
      );
      expect(widgetContinueMeta(pageLabel: 'p. 3', juzLabel: null), 'p. 3');
    });

    test('deep links', () {
      expect(
        widgetContinueDeepLink(18, 45),
        'quranoffline://read?resume=1&surah=18&ayah=45',
      );
      expect(widgetAyahDeepLink(94, 5), 'quranoffline://read?surah=94&ayah=5');
    });
  });

  group('widget copy', () {
    test('Indonesian strings use the spec wording', () {
      expect(
        AppLocalizations.formatWidgetAyahRef('Ash-Sharh', 94, 5, 'id'),
        'QS Ash-Sharh 94:5',
      );
      expect(
        AppLocalizations.formatWidgetAyahPosition(1, 3, 'id'),
        '1 dari 3 ayat',
      );
      expect(
        AppLocalizations.getWidgetContinueButton(297, 'id'),
        'Lanjutkan · Hal. 297',
      );
      expect(AppLocalizations.getWidgetReadReflection('id'), 'Baca renungan');
    });

    test('every language has copy and Indonesian uses kamu, never Anda', () {
      for (final lang in ['id', 'en', 'zh', 'ja']) {
        final strings = [
          AppLocalizations.getWidgetStartReadingHint(lang),
          AppLocalizations.formatWidgetProgressDescription(40, 'surah', lang),
          AppLocalizations.formatWidgetProgressDescription(40, 'juz', lang),
          AppLocalizations.formatWidgetProgressDescription(99, 'page', lang),
          AppLocalizations.getWidgetReadReflection(lang),
        ];
        expect(strings.every((s) => s.isNotEmpty), isTrue);
        if (lang == 'id') {
          expect(strings.any((s) => s.contains('kamu')), isTrue);
          expect(strings.any((s) => s.contains('Anda')), isFalse);
        }
      }
      expect(
        AppLocalizations.getWidgetReadReflection('zh'),
        isNot(AppLocalizations.getWidgetReadReflection('en')),
      );
    });
  });

  group('packGlyphLines', () {
    test('packs greedily and keeps oversized words on their own line', () {
      // Greedy would give [0,1] [2,3] [4]; balancing keeps 3 lines and
      // the orphan guard keeps the end marker (4) with a word.
      expect(packGlyphLines([40, 40, 40, 40, 40], 100), [
        [0, 1],
        [2],
        [3, 4],
      ]);
      // Balanced: 4 words of 30 in 2 lines of 2, not 3 + 1.
      expect(packGlyphLines([30, 30, 30, 30], 100), [
        [0, 1],
        [2, 3],
      ]);
      expect(packGlyphLines([150, 20], 100), [
        [0],
        [1],
      ]);
      expect(packGlyphLines([], 100), isEmpty);
    });
  });

  group('payload', () {
    test('round-trips the responsive widget fields', () {
      const original = BerandaWidgetPayload(
        tagline: '',
        reflectionLabel: 'Renungan minggu ini',
        reflectionTitle: 'Kesulitan dan kemudahan',
        reflectionRef: 'QS 94:5-6',
        reflectionBadge: '',
        continueLabel: 'Lanjutkan baca',
        readDeepLink: 'quranoffline://read?resume=1&surah=18&ayah=45',
        reflectionDeepLink: 'quranoffline://reflection',
        hasContinue: true,
        continueMeta: 'Hal. 297 · Juz 15',
        continuePercent: 49,
        ayahRef: 'QS Ash-Sharh 94:5',
        ayahPosition: '1 dari 2 ayat',
        ayahDeepLink: 'quranoffline://read?surah=94&ayah=5',
        ayahImageMedium: '/data/home_widget/widget_ayah_m.png',
      );
      final decoded = BerandaWidgetPayload.decode(original.encode());
      expect(decoded.continueMeta, 'Hal. 297 · Juz 15');
      expect(decoded.continuePercent, 49);
      expect(decoded.ayahRef, 'QS Ash-Sharh 94:5');
      expect(decoded.ayahImageMedium, endsWith('widget_ayah_m.png'));
      expect(decoded.ayahImageLarge, isNull);
    });
  });
}
