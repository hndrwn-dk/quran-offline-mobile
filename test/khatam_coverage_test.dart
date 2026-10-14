import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/support/ayah_dwell.dart';
import 'package:quran_offline/core/support/khatam_coverage.dart';
import 'package:quran_offline/core/support/quran_ayah_index.dart';
import 'package:quran_offline/core/support/reading_milestone.dart';

void main() {
  group('QuranAyahIndex', () {
    test('covers 6236 ayahs and matches bundled juz sizes', () {
      expect(QuranAyahIndex.totalAyahs, 6236);
      expect(QuranAyahIndex.juzAyahCount(1), 148);
      expect(QuranAyahIndex.juzAyahCount(10), 127);
      expect(QuranAyahIndex.juzAyahCount(30), 564);
      var sum = 0;
      for (var juz = 1; juz <= 30; juz++) {
        sum += QuranAyahIndex.juzAyahCount(juz);
      }
      expect(sum, 6236);
    });

    test('maps surah and ayah onto a juz', () {
      expect(QuranAyahIndex.juzOf(1, 1), 1);
      expect(QuranAyahIndex.juzOf(2, 141), 1);
      expect(QuranAyahIndex.juzOf(2, 142), 2);
      expect(QuranAyahIndex.juzOf(2, 252), 2);
      expect(QuranAyahIndex.juzOf(2, 253), 3);
      expect(QuranAyahIndex.juzOf(2, 286), 3);
      expect(QuranAyahIndex.globalIndex(1, 1), 0);
      expect(QuranAyahIndex.globalIndex(114, 6), 6235);
    });
  });

  group('AyahDwell', () {
    final t0 = DateTime(2026, 1, 1, 12);

    test('counts an ayah only after it stays visible for 2 seconds', () {
      final dwell = AyahDwell();
      expect(dwell.onVisible(const AyahRef(2, 255), t0), isNull);
      expect(
        dwell.onVisible(const AyahRef(2, 255), t0.add(const Duration(seconds: 1))),
        isNull,
      );
      expect(
        dwell.onVisible(const AyahRef(2, 255), t0.add(const Duration(seconds: 2))),
        const AyahRef(2, 255),
      );
      expect(
        dwell.onVisible(const AyahRef(2, 255), t0.add(const Duration(seconds: 5))),
        isNull,
      );
    });

    test('a jump away before 2 seconds does not count', () {
      final dwell = AyahDwell();
      dwell.onVisible(const AyahRef(112, 4), t0);
      expect(
        dwell.onVisible(const AyahRef(113, 1), t0.add(const Duration(milliseconds: 400))),
        isNull,
      );
      expect(
        dwell.onVisible(const AyahRef(113, 1), t0.add(const Duration(milliseconds: 2400))),
        const AyahRef(113, 1),
      );
    });
  });

  group('KhatamCoverage', () {
    test('repeat reads do not count again', () {
      final coverage = KhatamCoverage();
      final first = coverage.mark(2, 285);
      final second = coverage.mark(2, 286);
      final again = coverage.mark(2, 285);

      expect(first.counted, isTrue);
      expect(second.counted, isTrue);
      expect(again.counted, isFalse);
      expect(coverage.markedCount, 2);
    });

    test('a juz completes only when every ayah in it is set', () {
      final coverage = KhatamCoverage();
      final last = QuranAyahIndex.juzAyahCount(1) - 1;
      for (var i = 0; i < last; i++) {
        final update = coverage.markIndex(i);
        expect(update.completedJuz, isNull);
      }
      final done = coverage.mark(2, 141);
      expect(done.completedJuz, 1);
      expect(done.completedJuzCount, 1);
      expect(done.khatam, isFalse);
      expect(milestoneFor(done)!.kind, ReadingMilestoneKind.juz);
      expect(milestoneFor(done)!.juzNumber, 1);
    });

    test('the 10th completed juz is the ten-juz milestone', () {
      final coverage = KhatamCoverage();
      CoverageUpdate? last;
      for (var juz = 1; juz <= 10; juz++) {
        for (final index in QuranAyahIndex.indexesInJuz(juz)) {
          last = coverage.markIndex(index);
        }
      }
      expect(last!.completedJuzCount, 10);
      expect(last.khatam, isFalse);
      expect(milestoneFor(last)!.kind, ReadingMilestoneKind.ten);
    });

    test('khatam resets the bitset and increments the cycle', () {
      final coverage = KhatamCoverage();
      CoverageUpdate? last;
      for (var index = 0; index < QuranAyahIndex.totalAyahs; index++) {
        last = coverage.markIndex(index);
      }
      expect(last!.khatam, isTrue);
      expect(last.cycle, 1);
      expect(last.completedJuzCount, 30);
      expect(milestoneFor(last)!.kind, ReadingMilestoneKind.khatam);
      expect(coverage.cycle, 2);
      expect(coverage.markedCount, 0);
      expect(coverage.mark(1, 1).counted, isTrue);
    });

    test('bytes round-trip', () {
      final coverage = KhatamCoverage();
      coverage.mark(40, 85);
      final restored = KhatamCoverage.fromBytes(coverage.toBytes(), cycle: 3);
      expect(restored.cycle, 3);
      expect(restored.mark(40, 85).counted, isFalse);
      expect(restored.markedCount, 1);
    });
  });
}
