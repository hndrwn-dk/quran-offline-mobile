import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/reading/reading_activity_logic.dart';

void main() {
  group('isoWeekKey', () {
    test('same ISO week for Mon and Fri in same calendar week', () {
      final monday = DateTime(2026, 6, 29);
      final friday = DateTime(2026, 7, 3);
      expect(isoWeekKey(monday), isoWeekKey(friday));
    });

    test('different weeks across year boundary', () {
      expect(
        isoWeekKey(DateTime(2025, 12, 29)),
        isNot(isoWeekKey(DateTime(2026, 1, 5))),
      );
    });
  });

  group('hasReadInIsoWeek', () {
    test('returns true when activity date is in reference week', () {
      final dates = ['2026-07-01', '2026-06-15'];
      expect(hasReadInIsoWeek(dates, DateTime(2026, 7, 3)), isTrue);
    });

    test('returns false when no activity in reference week', () {
      final dates = ['2026-06-20', '2026-06-22'];
      expect(hasReadInIsoWeek(dates, DateTime(2026, 7, 3)), isFalse);
    });
  });

  group('addActivityDate', () {
    test('adds date without duplicates', () {
      final result = addActivityDate(['2026-07-01'], DateTime(2026, 7, 1, 18));
      expect(result.where((d) => d == '2026-07-01').length, 1);
    });
  });
}
