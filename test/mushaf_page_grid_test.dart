import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('strict 15-row grid', () {
    test('every layout row has the same pitch and fills the page', () {
      expect(
        kMushafPageRowHeight * kMushafPageLineCount,
        closeTo(kMushafPageLayoutHeight, 0.001),
      );
      expect(kMushafPageLineCount, 15);
      expect(kMushafPageAspectRatio, closeTo(0.65, 0.0001));
      expect(
        kMushafPageLayoutWidth / kMushafPageLayoutHeight,
        closeTo(kMushafPageAspectRatio, 1e-9),
      );
    });

    test('row pitch matches the QPC print line height (1.644 em)', () {
      final pitchEm = kMushafPageRowHeight / kMushafPageFontSize;
      expect(pitchEm, closeTo(1.641, 0.005));
      expect(kMushafPageFontSize, closeTo(22.375, 1e-9));
    });

    test('surah ink fits inside one row for every sample', () {
      for (final surah in [1, 2, 3, 33, 50, 112, 113, 114]) {
        final layout = layoutSurahNameInk(
          surahId: surah,
          targetInkHeight: kMushafPageRowHeight * kSurahNameInkHeightFactor,
          maxInkWidth: kMushafPageLayoutWidth * kSurahNameMaxInkWidthFactor,
        );
        expect(layout.inkHeight, lessThan(kMushafPageRowHeight),
            reason: 'surah $surah');
        expect(layout.inkWidth, lessThan(kMushafPageLayoutWidth),
            reason: 'surah $surah');
      }
    });
  });

  group('layout database', () {
    late Database db;

    setUpAll(() {
      db = sqlite3.open(
        'assets/mushaf/layout/qpc_v2_15_lines.sqlite',
        mode: OpenMode.readOnly,
      );
    });

    tearDownAll(() => db.dispose());

    int lineCount(int page) {
      return db.select(
        'SELECT COUNT(*) AS c FROM pages WHERE page_number = ?',
        [page],
      ).first['c'] as int;
    }

    test('pages 601 and 602 have 15 rows numbered 1..15', () {
      for (final page in [601, 602]) {
        expect(lineCount(page), 15, reason: 'page $page');
        final rows = db.select(
          'SELECT line_number FROM pages WHERE page_number = ? '
          'ORDER BY line_number',
          [page],
        );
        expect(
          rows.map((r) => r['line_number']).toList(),
          List<int>.generate(15, (i) => i + 1),
          reason: 'page $page',
        );
      }
    });

    test('every full page in the last spreads has 15 rows', () {
      for (final page in [582, 589, 591, 596, 601, 602, 603, 604]) {
        expect(lineCount(page), 15, reason: 'page $page');
      }
    });
  });
}
