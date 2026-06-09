enum HafalanDayKind {
  notStarted,
  newMemorization,
  murojaah,
  tahsin,
  completed,
}

class JuzAmmaUnit {
  final int sort;
  final int surah;
  final int from;
  final int to;

  const JuzAmmaUnit({
    required this.sort,
    required this.surah,
    required this.from,
    required this.to,
  });

  factory JuzAmmaUnit.fromJson(Map<String, dynamic> json) {
    final from = json['from'] as int;
    final to = (json['to'] as int?) ?? from;
    return JuzAmmaUnit(
      sort: json['sort'] as int,
      surah: json['surah'] as int,
      from: from,
      to: to,
    );
  }

  int get ayahCount => to - from + 1;
}

class JuzAmmaProgram {
  final int version;
  final int juz;
  final int tahsinDays;
  final List<JuzAmmaUnit> units;

  const JuzAmmaProgram({
    required this.version,
    required this.juz,
    required this.tahsinDays,
    required this.units,
  });

  factory JuzAmmaProgram.fromJson(Map<String, dynamic> json) {
    final units = (json['units'] as List<dynamic>)
        .map((e) => JuzAmmaUnit.fromJson(e as Map<String, dynamic>))
        .toList();
    return JuzAmmaProgram(
      version: json['version'] as int? ?? 1,
      juz: json['juz'] as int? ?? 30,
      tahsinDays: json['tahsinDays'] as int? ?? 5,
      units: units,
    );
  }

  static const int firstSurah = 78;
  static const int lastSurah = 114;
  static const int totalAyahs = 564;
}

class HafalanDayTask {
  final HafalanDayKind kind;
  final JuzAmmaUnit? unit;
  final int tahsinDay;
  final int tahsinTotal;
  final int programDayIndex;

  const HafalanDayTask({
    required this.kind,
    this.unit,
    this.tahsinDay = 0,
    this.tahsinTotal = 0,
    this.programDayIndex = 0,
  });

  factory HafalanDayTask.notStarted() {
    return const HafalanDayTask(kind: HafalanDayKind.notStarted);
  }

  factory HafalanDayTask.completed() {
    return const HafalanDayTask(kind: HafalanDayKind.completed);
  }
}

enum JuzAmmaHafalanMode { program, free }

/// Resolves today's task: weekdays = new unit; Friday = setoran/muroja'ah;
/// after all units = tahsin days.
HafalanDayTask resolveHafalanDay({
  required DateTime now,
  required DateTime programStart,
  required JuzAmmaProgram program,
}) {
  final start = DateTime(programStart.year, programStart.month, programStart.day);
  final today = DateTime(now.year, now.month, now.day);
  if (today.isBefore(start)) {
    return HafalanDayTask.notStarted();
  }

  var unitIndex = 0;
  var tahsinDay = 0;
  var dayIndex = 0;

  for (var d = start;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))) {
    dayIndex++;
    final isFriday = d.weekday == DateTime.friday;
    final isToday = d.year == today.year &&
        d.month == today.month &&
        d.day == today.day;

    if (isToday) {
      if (isFriday) {
        return HafalanDayTask(
          kind: HafalanDayKind.murojaah,
          programDayIndex: dayIndex,
        );
      }
      if (unitIndex < program.units.length) {
        return HafalanDayTask(
          kind: HafalanDayKind.newMemorization,
          unit: program.units[unitIndex],
          programDayIndex: dayIndex,
        );
      }
      if (tahsinDay < program.tahsinDays) {
        return HafalanDayTask(
          kind: HafalanDayKind.tahsin,
          tahsinDay: tahsinDay + 1,
          tahsinTotal: program.tahsinDays,
          programDayIndex: dayIndex,
        );
      }
      return HafalanDayTask.completed();
    }

    if (isFriday) continue;
    if (unitIndex < program.units.length) {
      unitIndex++;
    } else if (tahsinDay < program.tahsinDays) {
      tahsinDay++;
    }
  }

  return HafalanDayTask.completed();
}

bool isJuzAmmaSurah(int surahId) {
  return surahId >= JuzAmmaProgram.firstSurah &&
      surahId <= JuzAmmaProgram.lastSurah;
}

DateTime normalizeHafalanDate(DateTime d) =>
    DateTime(d.year, d.month, d.day);

/// ISO date key for the Friday of the week containing [now].
String fridayKeyFor(DateTime now) {
  final today = normalizeHafalanDate(now);
  var friday = today;
  while (friday.weekday != DateTime.friday) {
    friday = friday.subtract(const Duration(days: 1));
  }
  return friday.toIso8601String().split('T').first;
}

String setoranItemKey(JuzAmmaUnit unit) => 'u:${unit.sort}';

/// Saturday after previous Friday through Thursday before this Friday.
({DateTime start, DateTime end}) fridaySetoranWindow(DateTime now) {
  final today = normalizeHafalanDate(now);
  var thisFriday = today;
  while (thisFriday.weekday != DateTime.friday) {
    thisFriday = thisFriday.subtract(const Duration(days: 1));
  }
  final previousFriday = thisFriday.subtract(const Duration(days: 7));
  final start = previousFriday.add(const Duration(days: 1));
  final end = thisFriday.subtract(const Duration(days: 1));
  return (start: start, end: end);
}

/// Units scheduled for new memorization during the current setoran window.
List<JuzAmmaUnit> resolveFridaySetoranQueue({
  required DateTime now,
  required DateTime programStart,
  required JuzAmmaProgram program,
}) {
  final today = normalizeHafalanDate(now);
  final window = fridaySetoranWindow(now);
  if (today.weekday != DateTime.friday) return [];
  if (window.end.isBefore(window.start)) return [];

  final start = normalizeHafalanDate(programStart);
  final queue = <JuzAmmaUnit>[];
  var unitIndex = 0;

  for (var d = start;
      !d.isAfter(window.end) && unitIndex < program.units.length;
      d = d.add(const Duration(days: 1))) {
    if (d.weekday == DateTime.friday) continue;
    if (!d.isBefore(window.start)) {
      queue.add(program.units[unitIndex]);
    }
    unitIndex++;
  }
  return queue;
}

/// Free mode: surah ranges for ayahs marked memorized in the setoran window.
List<JuzAmmaUnit> resolveFridaySetoranQueueFromMemorized({
  required DateTime now,
  required List<({int surahId, int ayahNo, DateTime completedAt})> rows,
}) {
  final today = normalizeHafalanDate(now);
  final window = fridaySetoranWindow(now);
  if (today.weekday != DateTime.friday) return [];
  if (window.end.isBefore(window.start)) return [];

  final inWindow = rows.where((r) {
    final day = normalizeHafalanDate(r.completedAt);
    return !day.isBefore(window.start) && !day.isAfter(window.end);
  }).toList();
  if (inWindow.isEmpty) return [];

  final bySurah = <int, List<int>>{};
  for (final r in inWindow) {
    bySurah.putIfAbsent(r.surahId, () => []).add(r.ayahNo);
  }

  final surahs = bySurah.keys.toList()..sort((a, b) => b.compareTo(a));
  var sort = 1;
  return surahs.map((surahId) {
    final ayahs = bySurah[surahId]!..sort();
    return JuzAmmaUnit(
      sort: sort++,
      surah: surahId,
      from: ayahs.first,
      to: ayahs.last,
    );
  }).toList();
}

/// Program units with at least one ayah already marked memorized (murojaah fallback).
List<JuzAmmaUnit> resolveFridaySetoranQueueFromPartialProgram({
  required JuzAmmaProgram program,
  required Set<String> memorizedKeys,
}) {
  return program.units.where((unit) {
    for (var a = unit.from; a <= unit.to; a++) {
      if (memorizedKeys.contains('${unit.surah}:$a')) return true;
    }
    return false;
  }).toList();
}

/// Free mode fallback: every Juz Amma surah that has memorized ayahs.
List<JuzAmmaUnit> resolveFridaySetoranQueueFromAllMemorized({
  required Set<String> memorizedKeys,
}) {
  final bySurah = <int, List<int>>{};
  for (final key in memorizedKeys) {
    final parts = key.split(':');
    if (parts.length != 2) continue;
    final surahId = int.tryParse(parts[0]);
    final ayahNo = int.tryParse(parts[1]);
    if (surahId == null || ayahNo == null) continue;
    if (!isJuzAmmaSurah(surahId)) continue;
    bySurah.putIfAbsent(surahId, () => []).add(ayahNo);
  }
  if (bySurah.isEmpty) return [];

  final surahs = bySurah.keys.toList()..sort((a, b) => b.compareTo(a));
  var sort = 1;
  return surahs.map((surahId) {
    final ayahs = bySurah[surahId]!..sort();
    return JuzAmmaUnit(
      sort: sort++,
      surah: surahId,
      from: ayahs.first,
      to: ayahs.last,
    );
  }).toList();
}
