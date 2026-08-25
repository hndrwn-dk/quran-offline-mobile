import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';

class ReflectionTrigger {
  final String type;
  final int? weekday;
  final int? hijriMonth;
  final int? hijriDay;
  final int? hijriDayFrom;
  final int? hijriDayTo;
  final List<ReflectionSlot>? slots;
  final String? period;

  const ReflectionTrigger({
    required this.type,
    this.weekday,
    this.hijriMonth,
    this.hijriDay,
    this.hijriDayFrom,
    this.hijriDayTo,
    this.slots,
    this.period,
  });

  factory ReflectionTrigger.fromJson(Map<String, dynamic> json) {
    return ReflectionTrigger(
      type: json['type'] as String,
      weekday: json['weekday'] as int?,
      hijriMonth: json['month'] as int?,
      hijriDay: json['day'] as int?,
      hijriDayFrom: json['dayFrom'] as int?,
      hijriDayTo: json['dayTo'] as int?,
      slots: _parseSlots(json['slots']),
      period: json['period'] as String?,
    );
  }

  bool appliesInSlot(ReflectionSlot slot) {
    final allowed = slots;
    if (allowed == null || allowed.isEmpty) return true;
    return allowed.contains(slot);
  }

  bool matches(DateTime gregorian, HijriDate hijri) {
    return switch (type) {
      'weekday' => gregorian.weekday == weekday,
      'hijri_month' => hijri.month == hijriMonth,
      'hijri_day' => hijri.month == hijriMonth && _hijriDayMatches(hijri.day),
      'time_of_day' => _matchesPeriod(gregorian.hour, period),
      _ => false,
    };
  }

  bool _hijriDayMatches(int day) {
    final from = hijriDayFrom;
    final to = hijriDayTo;
    if (from != null && to != null) {
      return day >= from && day <= to;
    }
    return day == hijriDay;
  }

  static List<ReflectionSlot>? _parseSlots(Object? raw) {
    if (raw == null) return null;
    final list = raw as List<dynamic>;
    final slots = <ReflectionSlot>[];
    for (final item in list) {
      final slot = switch (item as String) {
        'morning' => ReflectionSlot.morning,
        'midday' => ReflectionSlot.midday,
        'evening' => ReflectionSlot.evening,
        _ => null,
      };
      if (slot != null) slots.add(slot);
    }
    return slots;
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
