import 'package:hijri/hijri_calendar.dart';

/// Hijri date for calendar triggers (Ramadan, 1 Muharram, etc.).
/// Uses tabular conversion; may differ by one day from local announcements.
class HijriDate {
  final int year;
  final int month;
  final int day;

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });

  factory HijriDate.fromGregorian(DateTime gregorian) {
    final h = HijriCalendar.fromDate(gregorian);
    return HijriDate(
      year: h.hYear,
      month: h.hMonth,
      day: h.hDay,
    );
  }
}

enum TimeOfDayPeriod { morning, evening }

TimeOfDayPeriod? timeOfDayPeriodForHour(int hour) {
  if (hour >= 5 && hour < 12) return TimeOfDayPeriod.morning;
  if (hour >= 18 && hour < 22) return TimeOfDayPeriod.evening;
  return null;
}

int isoWeekOfYear(DateTime date) {
  final utc = DateTime.utc(date.year, date.month, date.day);
  final weekday = utc.weekday;
  final thursday = utc.add(Duration(days: 4 - weekday));
  final yearStart = DateTime.utc(thursday.year, 1, 1);
  return 1 + ((thursday.difference(yearStart).inDays) ~/ 7);
}
