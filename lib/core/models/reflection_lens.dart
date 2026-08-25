import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';

enum ReflectionTier { fixedDate, season, weekday, ambient }

class HijriDay {
  final int month;
  final int day;

  const HijriDay({required this.month, required this.day});

  factory HijriDay.fromJson(Map<String, dynamic> json) {
    return HijriDay(
      month: json['month'] as int,
      day: json['day'] as int,
    );
  }
}

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

  bool matches(IslamicDay day) {
    return switch (type) {
      'weekday' => day.weekday == weekday,
      'hijri_month' => day.hijri.month == hijriMonth,
      'hijri_day' =>
        day.hijri.month == hijriMonth && _hijriDayMatches(day.hijri.day),
      'time_of_day' => _matchesPeriod(day.period, period),
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

  static bool _matchesPeriod(TimeOfDayPeriod? current, String? expected) {
    if (current == null || expected == null) return false;
    return switch (expected) {
      'morning' => current == TimeOfDayPeriod.morning,
      'evening' => current == TimeOfDayPeriod.evening,
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
  final String? poolIdOverride;
  final int? weightOverride;
  final ReflectionTier? tierOverride;
  final List<HijriDay> forbidOn;

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
    this.poolIdOverride,
    this.weightOverride,
    this.tierOverride,
    this.forbidOn = const [],
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
      poolIdOverride: json['poolId'] as String?,
      weightOverride: json['weight'] as int?,
      tierOverride: _parseTier(json['tier']),
      forbidOn: _parseForbidOn(json['forbidOn']),
    );
  }

  String get poolId => poolIdOverride ?? id;

  int get weight {
    final w = weightOverride ?? (trigger?.type == 'time_of_day' ? 3 : 1);
    return w < 1 ? 1 : w;
  }

  ReflectionTier get tier {
    if (tierOverride != null) return tierOverride!;
    return switch (trigger?.type) {
      'hijri_day' => ReflectionTier.fixedDate,
      'hijri_month' => ReflectionTier.season,
      'weekday' => ReflectionTier.weekday,
      _ => ReflectionTier.ambient,
    };
  }

  bool isForbiddenOn(HijriDate hijri) {
    for (final day in forbidOn) {
      if (day.month == hijri.month && day.day == hijri.day) return true;
    }
    return false;
  }

  bool get showsOccasionBadge {
    return tier == ReflectionTier.fixedDate || tier == ReflectionTier.season;
  }

  DuaAyahRef get primaryRef => ayahRefs.first;

  int get ayahCount {
    var count = 0;
    for (final ref in ayahRefs) {
      count += ref.to - ref.from + 1;
    }
    return count;
  }

  static ReflectionTier? _parseTier(Object? raw) {
    return switch (raw) {
      'fixedDate' => ReflectionTier.fixedDate,
      'season' => ReflectionTier.season,
      'weekday' => ReflectionTier.weekday,
      'ambient' => ReflectionTier.ambient,
      _ => null,
    };
  }

  static List<HijriDay> _parseForbidOn(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => HijriDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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
