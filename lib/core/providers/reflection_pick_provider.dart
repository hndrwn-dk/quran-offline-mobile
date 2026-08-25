import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reflection_fallback.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_history_store.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';

const _calendarAsset = 'assets/reflection/calendar_lenses_catalog.json';
const _weeklyAsset = 'assets/reflection/weekly_rotation_catalog.json';

class ReflectionCatalog {
  final int version;
  final List<ReflectionLensEntry> entries;

  const ReflectionCatalog({required this.version, required this.entries});
}

Future<ReflectionCatalog> _loadCatalog(String assetPath) async {
  try {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = (json['entries'] as List<dynamic>)
        .map((e) => ReflectionLensEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReflectionCatalog(
      version: json['version'] as int? ?? 1,
      entries: items,
    );
  } catch (e, st) {
    debugPrint('Reflection catalog load failed ($assetPath): $e\n$st');
    return const ReflectionCatalog(version: 0, entries: []);
  }
}

final calendarLensesProvider = FutureProvider<ReflectionCatalog>((ref) async {
  return _loadCatalog(_calendarAsset);
});

final weeklyRotationProvider = FutureProvider<ReflectionCatalog>((ref) async {
  return _loadCatalog(_weeklyAsset);
});

int _localEpochDay(DateTime now) {
  final local = DateTime(now.year, now.month, now.day);
  return local.difference(DateTime(1970, 1, 1)).inDays;
}

List<ReflectionLensEntry> _sortPriorityDesc(List<ReflectionLensEntry> list) {
  final copy = [...list];
  copy.sort((a, b) {
    final byPriority = b.priority.compareTo(a.priority);
    if (byPriority != 0) return byPriority;
    return a.sort.compareTo(b.sort);
  });
  return copy;
}

List<ReflectionLensEntry> _sortPriorityAsc(List<ReflectionLensEntry> list) {
  final copy = [...list];
  copy.sort((a, b) {
    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) return byPriority;
    return a.sort.compareTo(b.sort);
  });
  return copy;
}

bool _isType(ReflectionLensEntry e, String type) => e.trigger?.type == type;

List<ReflectionLensEntry> _matching(
  List<ReflectionLensEntry> calendar,
  DateTime now,
  HijriDate hijri,
  ReflectionSlot slot,
  bool Function(ReflectionLensEntry e) predicate,
) {
  return calendar.where((e) {
    final t = e.trigger;
    if (t == null) return false;
    if (!t.appliesInSlot(slot)) return false;
    if (!t.matches(now, hijri)) return false;
    return predicate(e);
  }).toList();
}

ReflectionPick resolveReflectionPick({
  required DateTime now,
  required HijriDate hijri,
  required List<ReflectionLensEntry> calendarEntries,
  required List<ReflectionLensEntry> weeklyEntries,
}) {
  final slot = reflectionSlotForHour(now.hour);

  ReflectionPick? from(ReflectionLensEntry? e, ReflectionPickSource source) {
    if (e == null) return null;
    return ReflectionPick(entry: e, source: source);
  }

  ReflectionLensEntry? firstDesc(List<ReflectionLensEntry> list) =>
      list.isEmpty ? null : _sortPriorityDesc(list).first;

  if (slot == ReflectionSlot.evening) {
    final hijriDay = _matching(
      calendarEntries,
      now,
      hijri,
      slot,
      (e) => _isType(e, 'hijri_day'),
    );
    final hijriPick = from(firstDesc(hijriDay), ReflectionPickSource.calendar);
    if (hijriPick != null) return hijriPick;

    if (now.weekday == DateTime.thursday) {
      final friday = calendarEntries.where((e) {
        final t = e.trigger;
        return t != null &&
            t.type == 'weekday' &&
            t.weekday == DateTime.friday &&
            t.appliesInSlot(slot);
      }).toList();
      final kahf = from(firstDesc(friday), ReflectionPickSource.calendar);
      if (kahf != null) return kahf;
    }

    final evening = _matching(
      calendarEntries,
      now,
      hijri,
      slot,
      (e) => _isType(e, 'time_of_day'),
    );
    final night = from(firstDesc(evening), ReflectionPickSource.timeOfDay);
    if (night != null) return night;
  } else {
    final hijriDay = _matching(
      calendarEntries,
      now,
      hijri,
      slot,
      (e) => _isType(e, 'hijri_day'),
    );
    final dayPick = from(firstDesc(hijriDay), ReflectionPickSource.calendar);
    if (dayPick != null) return dayPick;

    final hijriMonth = _matching(
      calendarEntries,
      now,
      hijri,
      slot,
      (e) => _isType(e, 'hijri_month'),
    );
    final monthPick =
        from(firstDesc(hijriMonth), ReflectionPickSource.calendar);
    if (monthPick != null) return monthPick;

    final weekday = _matching(
      calendarEntries,
      now,
      hijri,
      slot,
      (e) => _isType(e, 'weekday'),
    );
    if (weekday.isNotEmpty) {
      final chosen = now.weekday == DateTime.friday &&
              slot == ReflectionSlot.midday &&
              weekday.length > 1
          ? _sortPriorityAsc(weekday).first
          : _sortPriorityDesc(weekday).first;
      return ReflectionPick(
        entry: chosen,
        source: ReflectionPickSource.calendar,
      );
    }

    if (slot == ReflectionSlot.morning) {
      final morning = _matching(
        calendarEntries,
        now,
        hijri,
        slot,
        (e) => _isType(e, 'time_of_day'),
      );
      final m = from(firstDesc(morning), ReflectionPickSource.timeOfDay);
      if (m != null) return m;
    }
  }

  final sortedWeekly = [...weeklyEntries]
    ..sort((a, b) => a.sort.compareTo(b.sort));
  if (sortedWeekly.isEmpty) {
    throw StateError('Weekly reflection catalog is empty');
  }
  final index = _localEpochDay(now).abs() % sortedWeekly.length;
  return ReflectionPick(
    entry: sortedWeekly[index],
    source: ReflectionPickSource.weekly,
  );
}

ReflectionPickSource _sourceFromTrigger(ReflectionTrigger? trigger) {
  if (trigger == null) return ReflectionPickSource.weekly;
  if (trigger.type == 'time_of_day') return ReflectionPickSource.timeOfDay;
  return ReflectionPickSource.calendar;
}

final reflectionNowProvider = Provider<DateTime>((ref) => DateTime.now());

final reflectionPickProvider = FutureProvider<ReflectionPick>((ref) async {
  final now = ref.watch(reflectionNowProvider);
  var calendar = await ref.watch(calendarLensesProvider.future);
  var weekly = await ref.watch(weeklyRotationProvider.future);
  if (weekly.entries.isEmpty) {
    weekly = const ReflectionCatalog(
      version: 0,
      entries: kReflectionFallbackEntries,
    );
  }
  final hijri = HijriDate.fromGregorian(now);
  final slot = reflectionSlotForHour(now.hour);
  final store = ReflectionHistoryStore();
  final ymd = store.localYmd(now);
  final cached = await store.read();
  if (cached != null && cached.ymd == ymd && cached.slot == slot) {
    for (final e in [...calendar.entries, ...weekly.entries]) {
      if (e.id == cached.id) {
        return ReflectionPick(
          entry: e,
          source: _sourceFromTrigger(e.trigger),
        );
      }
    }
  }
  final pick = resolveReflectionPick(
    now: now,
    hijri: hijri,
    calendarEntries: calendar.entries,
    weeklyEntries: weekly.entries,
  );
  await store.write(
    ReflectionSlotCache(ymd: ymd, slot: slot, id: pick.entry.id),
  );
  return pick;
});
