import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

void main() {
  test('HijriDate converts Gregorian to plausible Hijri values', () {
    final h = HijriDate.fromGregorian(DateTime(2024, 7, 7));
    expect(h.year, inInclusiveRange(1440, 1450));
    expect(h.month, inInclusiveRange(1, 12));
    expect(h.day, inInclusiveRange(1, 30));
  });

  test('isoWeekOfYear is stable within the same week', () {
    final monday = DateTime(2025, 3, 3);
    final sunday = DateTime(2025, 3, 9);
    expect(isoWeekOfYear(monday), isoWeekOfYear(sunday));
  });

  test('timeOfDayPeriodForHour matches morning and evening windows', () {
    expect(timeOfDayPeriodForHour(8), TimeOfDayPeriod.morning);
    expect(timeOfDayPeriodForHour(19), TimeOfDayPeriod.evening);
    expect(timeOfDayPeriodForHour(14), isNull);
  });
}
