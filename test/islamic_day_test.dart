import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

void main() {
  test('kMaghribRolloverHour is 18', () {
    expect(kMaghribRolloverHour, 18);
  });

  test('Thursday 20:00 rolls weekday to Friday', () {
    final now = DateTime(2026, 8, 20, 20);
    expect(now.weekday, DateTime.thursday);
    final day = IslamicDay.fromDateTime(now);
    expect(day.weekday, DateTime.friday);
    expect(day.period, TimeOfDayPeriod.evening);
  });

  test('Thursday 17:00 does not roll', () {
    final now = DateTime(2026, 8, 20, 17);
    expect(now.weekday, DateTime.thursday);
    final day = IslamicDay.fromDateTime(now);
    expect(day.weekday, DateTime.thursday);
    expect(day.period, isNull);
  });

  test('Friday 07:00 stays Friday', () {
    final now = DateTime(2026, 8, 21, 7);
    expect(now.weekday, DateTime.friday);
    final day = IslamicDay.fromDateTime(now);
    expect(day.weekday, DateTime.friday);
    expect(day.period, TimeOfDayPeriod.morning);
  });

  test('Friday 20:00 rolls to Saturday', () {
    final now = DateTime(2026, 8, 21, 20);
    expect(now.weekday, DateTime.friday);
    final day = IslamicDay.fromDateTime(now);
    expect(day.weekday, DateTime.saturday);
  });

  test('rolled Hijri matches next civil date', () {
    final evening = DateTime(2026, 8, 20, 20);
    final nextMorning = DateTime(2026, 8, 21, 7);
    expect(
      IslamicDay.fromDateTime(evening).hijri.ymdKey,
      IslamicDay.fromDateTime(nextMorning).hijri.ymdKey,
    );
  });
}
