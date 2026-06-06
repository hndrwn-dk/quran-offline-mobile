import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

class ReflectionTrigger {
  final String type;
  final int? weekday;
  final int? hijriMonth;
  final int? hijriDay;
  final String? period;

  const ReflectionTrigger({
    required this.type,
    this.weekday,
    this.hijriMonth,
    this.hijriDay,
    this.period,
  });

  factory ReflectionTrigger.fromJson(Map<String, dynamic> json) {
    return ReflectionTrigger(
      type: json['type'] as String,
      weekday: json['weekday'] as int?,
      hijriMonth: json['month'] as int?,
      hijriDay: json['day'] as int?,
      period: json['period'] as String?,
    );
  }

  bool matches(DateTime gregorian, HijriDate hijri) {
    return switch (type) {
      'weekday' => gregorian.weekday == weekday,
      'hijri_month' => hijri.month == hijriMonth,
      'hijri_day' =>
        hijri.month == hijriMonth && hijri.day == hijriDay,
      'time_of_day' => _matchesPeriod(gregorian.hour, period),
      _ => false,
    };
  }

  static bool _matchesPeriod(int hour, String? period) {
    final slot = timeOfDayPeriodForHour(hour);
    if (slot == null || period == null) return false;
    return switch (period) {
      'morning' => slot == TimeOfDayPeriod.morning,
      'evening' => slot == TimeOfDayPeriod.evening,
      _ => false,
    };
  }
}

class ReflectionLensEntry {
  final String id;
  final int sort;
  final int priority;
  final String badgeKey;
  final LocalizedText title;
  final LocalizedText summary;
  final LocalizedText reflection;
  final List<DuaAyahRef> ayahRefs;
  final ReflectionTrigger? trigger;

  const ReflectionLensEntry({
    required this.id,
    required this.sort,
    required this.priority,
    required this.badgeKey,
    required this.title,
    required this.summary,
    required this.reflection,
    required this.ayahRefs,
    this.trigger,
  });

  factory ReflectionLensEntry.fromJson(Map<String, dynamic> json) {
    final refs = (json['ayahRefs'] as List<dynamic>)
        .map((e) => DuaAyahRef.fromJson(e as Map<String, dynamic>))
        .toList();
    final triggerRaw = json['trigger'];
    return ReflectionLensEntry(
      id: json['id'] as String,
      sort: json['sort'] as int? ?? 0,
      priority: json['priority'] as int? ?? 0,
      badgeKey: json['badgeKey'] as String? ?? 'weekly',
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      summary: LocalizedText.fromJson(json['summary'] as Map<String, dynamic>),
      reflection:
          LocalizedText.fromJson(json['reflection'] as Map<String, dynamic>),
      ayahRefs: refs,
      trigger: triggerRaw == null
          ? null
          : ReflectionTrigger.fromJson(triggerRaw as Map<String, dynamic>),
    );
  }

  DuaAyahRef get primaryRef => ayahRefs.first;

  int get ayahCount {
    var count = 0;
    for (final ref in ayahRefs) {
      count += ref.to - ref.from + 1;
    }
    return count;
  }
}

enum ReflectionPickSource { calendar, timeOfDay, weekly }

class ReflectionPick {
  final ReflectionLensEntry entry;
  final ReflectionPickSource source;

  const ReflectionPick({
    required this.entry,
    required this.source,
  });
}
