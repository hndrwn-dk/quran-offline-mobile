import 'package:hijri/hijri_calendar.dart';

/// Civil-clock hour at which the Islamic day rolls forward.
/// TODO: source from a prayer-times API; do not add settings, location, or network in this pass.
const kMaghribRolloverHour = 18;

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

  String get ymdKey {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

enum TimeOfDayPeriod { morning, evening }

TimeOfDayPeriod? timeOfDayPeriodForHour(int hour) {
  if (hour >= 5 && hour < 12) return TimeOfDayPeriod.morning;
  if (hour >= kMaghribRolloverHour || hour < 5) {
    return TimeOfDayPeriod.evening;
  }
  return null;
}

/// Single day authority: Hijri and weekday rolled at maghrib.
class IslamicDay {
  final HijriDate hijri;
  final int weekday;
  final TimeOfDayPeriod? period;

  const IslamicDay({
    required this.hijri,
    required this.weekday,
    required this.period,
  });

  factory IslamicDay.fromDateTime(
    DateTime now, {
    int maghribHour = kMaghribRolloverHour,
  }) {
    final rolled = now.hour >= maghribHour
        ? DateTime(now.year, now.month, now.day + 1)
        : DateTime(now.year, now.month, now.day);
    return IslamicDay(
      hijri: HijriDate.fromGregorian(rolled),
      weekday: rolled.weekday,
      period: timeOfDayPeriodForHour(now.hour),
    );
  }
}

int isoWeekOfYear(DateTime date) {
  final utc = DateTime.utc(date.year, date.month, date.day);
  final weekday = utc.weekday;
  final thursday = utc.add(Duration(days: 4 - weekday));
  final yearStart = DateTime.utc(thursday.year, 1, 1);
  return 1 + ((thursday.difference(yearStart).inDays) ~/ 7);
}
