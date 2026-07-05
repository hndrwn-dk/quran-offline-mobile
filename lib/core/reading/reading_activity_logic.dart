/// Pure helpers for weekly reading activity tracking.
library;

/// Local calendar date key `YYYY-MM-DD` (no time component).
String localDateKey(DateTime dateTime) {
  final local = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// ISO-8601 week key like `2026-W27` (Monday-based weeks).
String isoWeekKey(DateTime localDate) {
  final normalized = DateTime(localDate.year, localDate.month, localDate.day);
  final thursday = normalized.add(Duration(days: 4 - normalized.weekday));
  final year = thursday.year;
  final jan4 = DateTime(year, 1, 4);
  final jan4Thursday = jan4.add(Duration(days: 4 - jan4.weekday));
  final weekNum =
      ((thursday.difference(jan4Thursday).inDays) / 7).floor() + 1;
  return '$year-W$weekNum';
}

bool hasReadInIsoWeek(
  Iterable<String> activityDateKeys,
  DateTime referenceLocalDate,
) {
  final targetWeek = isoWeekKey(referenceLocalDate);
  for (final key in activityDateKeys) {
    final parts = key.split('-');
    if (parts.length != 3) continue;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) continue;
    if (isoWeekKey(DateTime(year, month, day)) == targetWeek) {
      return true;
    }
  }
  return false;
}

/// Keep at most [maxEntries] most recent dates; drops keys older than 400 days.
List<String> pruneActivityDates(
  Iterable<String> dateKeys, {
  int maxEntries = 60,
}) {
  final parsed = <DateTime>[];
  for (final key in dateKeys) {
    final parts = key.split('-');
    if (parts.length != 3) continue;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) continue;
    parsed.add(DateTime(year, month, day));
  }
  parsed.sort((a, b) => b.compareTo(a));
  final cutoff = DateTime.now().subtract(const Duration(days: 400));
  final kept = parsed
      .where((d) => !d.isBefore(cutoff))
      .take(maxEntries)
      .map(localDateKey)
      .toList();
  return kept;
}

List<String> addActivityDate(
  Iterable<String> existing,
  DateTime when,
) {
  final key = localDateKey(when);
  final set = {...existing, key};
  return pruneActivityDates(set);
}
