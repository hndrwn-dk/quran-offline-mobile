import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

const _calendarAsset = 'assets/reflection/calendar_lenses_catalog.json';
const _weeklyAsset = 'assets/reflection/weekly_rotation_catalog.json';

class ReflectionCatalog {
  final int version;
  final List<ReflectionLensEntry> entries;

  const ReflectionCatalog({required this.version, required this.entries});
}

Future<ReflectionCatalog> _loadCatalog(String assetPath) async {
  String raw;
  try {
    raw = await rootBundle.loadString(assetPath);
  } catch (e, st) {
    debugPrint('Reflection asset missing ($assetPath): $e\n$st');
    rethrow;
  }
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final items = (json['entries'] as List<dynamic>)
      .map((e) => ReflectionLensEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  return ReflectionCatalog(
    version: json['version'] as int? ?? 1,
    entries: items,
  );
}

final calendarLensesProvider = FutureProvider<ReflectionCatalog>((ref) async {
  return _loadCatalog(_calendarAsset);
});

final weeklyRotationProvider = FutureProvider<ReflectionCatalog>((ref) async {
  return _loadCatalog(_weeklyAsset);
});

ReflectionPick resolveReflectionPick({
  required DateTime now,
  required List<ReflectionLensEntry> calendarEntries,
  required List<ReflectionLensEntry> weeklyEntries,
}) {
  final hijri = HijriDate.fromGregorian(now);

  final calendarMatches = calendarEntries.where((e) {
    final trigger = e.trigger;
    return trigger != null && trigger.matches(now, hijri);
  }).toList();

  if (calendarMatches.isNotEmpty) {
    calendarMatches.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) return byPriority;
      return a.sort.compareTo(b.sort);
    });
    final winner = calendarMatches.first;
    final source = winner.trigger?.type == 'time_of_day'
        ? ReflectionPickSource.timeOfDay
        : ReflectionPickSource.calendar;
    return ReflectionPick(entry: winner, source: source);
  }

  final sortedWeekly = List<ReflectionLensEntry>.from(weeklyEntries)
    ..sort((a, b) => a.sort.compareTo(b.sort));
  if (sortedWeekly.isEmpty) {
    throw StateError('Weekly reflection catalog is empty');
  }

  final week = isoWeekOfYear(now);
  final index = (week - 1) % sortedWeekly.length;
  return ReflectionPick(
    entry: sortedWeekly[index],
    source: ReflectionPickSource.weekly,
  );
}

final reflectionPickProvider = FutureProvider<ReflectionPick>((ref) async {
  final calendar = await ref.watch(calendarLensesProvider.future);
  final weekly = await ref.watch(weeklyRotationProvider.future);
  return resolveReflectionPick(
    now: DateTime.now(),
    calendarEntries: calendar.entries,
    weeklyEntries: weekly.entries,
  );
});
