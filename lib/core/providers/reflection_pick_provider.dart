import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reflection_fallback.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_history_provider.dart';
import 'package:quran_offline/core/providers/reflection_history_store.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/utils/home_tagline.dart';

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

const _tierRank = {
  ReflectionTier.fixedDate: 0,
  ReflectionTier.season: 1,
  ReflectionTier.weekday: 2,
  ReflectionTier.ambient: 3,
};

const _tiersDescending = [
  ReflectionTier.fixedDate,
  ReflectionTier.season,
  ReflectionTier.weekday,
  ReflectionTier.ambient,
];

int reflectionRecentCap(int eligibleCount) {
  return (eligibleCount - 1).clamp(1, 5);
}

List<String> trimRecentIds(List<String> recentIds, int eligibleCount) {
  final cap = reflectionRecentCap(eligibleCount);
  if (recentIds.length <= cap) return recentIds;
  return recentIds.sublist(0, cap);
}

bool _isOccasion(ReflectionTier tier) =>
    tier == ReflectionTier.fixedDate || tier == ReflectionTier.season;

List<ReflectionLensEntry> _takeSeeded(
  List<ReflectionLensEntry> list,
  int n,
  int seed,
) {
  if (list.length <= n) return list;
  final copy = [...list]..shuffle(Random(seed));
  return copy.take(n).toList();
}

ReflectionLensEntry _pickByWeight(
  List<ReflectionLensEntry> entries,
  Random rng,
) {
  var total = 0;
  for (final e in entries) {
    total += e.weight;
  }
  var dart = rng.nextInt(total);
  for (final e in entries) {
    dart -= e.weight;
    if (dart < 0) return e;
  }
  return entries.last;
}

ReflectionPick resolveReflectionPick({
  required IslamicDay day,
  required List<ReflectionLensEntry> calendarEntries,
  required List<ReflectionLensEntry> weeklyEntries,
  String seedSalt = '',
  List<String> recentIds = const [],
}) {
  final all = [...calendarEntries, ...weeklyEntries];
  final eligible = <ReflectionLensEntry>[];
  for (final entry in all) {
    if (entry.isForbiddenOn(day.hijri)) continue;
    final trigger = entry.trigger;
    if (trigger == null || trigger.matches(day)) {
      eligible.add(entry);
    }
  }
  if (eligible.isEmpty) {
    throw StateError('Weekly reflection catalog is empty');
  }

  List<ReflectionLensEntry> ofTier(ReflectionTier tier) =>
      eligible.where((e) => e.tier == tier).toList();

  var bestRank = 99;
  for (final entry in eligible) {
    final rank = _tierRank[entry.tier] ?? 99;
    if (rank < bestRank) bestRank = rank;
  }
  final primaryTier = _tiersDescending.firstWhere(
    (t) => (_tierRank[t] ?? 99) == bestRank,
  );
  final primary = ofTier(primaryTier);
  final seed = fnv1a32('$seedSalt|${day.hijri.ymdKey}');
  final rng = Random(seed);

  List<ReflectionLensEntry> pool;
  var borrowed = <ReflectionLensEntry>[];

  if (_isOccasion(primaryTier)) {
    pool = primary;
  } else {
    final blocked = trimRecentIds(recentIds, primary.length).toSet();
    List<ReflectionLensEntry> withoutRecent(List<ReflectionLensEntry> list) =>
        list.where((e) => !blocked.contains(e.id)).toList();
    pool = withoutRecent(primary);
    if (pool.length < 3) {
      var nextIndex = _tiersDescending.indexOf(primaryTier) + 1;
      while (borrowed.length < 3 && nextIndex < _tiersDescending.length) {
        final next = withoutRecent(ofTier(_tiersDescending[nextIndex]));
        final need = 3 - borrowed.length;
        borrowed.addAll(_takeSeeded(next, need, seed ^ nextIndex));
        nextIndex++;
      }
    }
    if (pool.isEmpty && borrowed.isEmpty) {
      pool = primary;
    }
  }

  late final ReflectionLensEntry chosen;
  if (pool.isEmpty && borrowed.isNotEmpty) {
    chosen = _pickByWeight(borrowed, rng);
  } else if (borrowed.isEmpty) {
    chosen = _pickByWeight(pool, rng);
  } else if (rng.nextInt(10) < 7) {
    chosen = _pickByWeight(pool, rng);
  } else {
    chosen = _pickByWeight(borrowed, rng);
  }

  return ReflectionPick(
    entry: chosen,
    source: _sourceFor(chosen),
  );
}

ReflectionPickSource _sourceFor(ReflectionLensEntry entry) {
  switch (entry.tier) {
    case ReflectionTier.fixedDate:
    case ReflectionTier.season:
    case ReflectionTier.weekday:
      return ReflectionPickSource.calendar;
    case ReflectionTier.ambient:
      if (entry.trigger?.type == 'time_of_day') {
        return ReflectionPickSource.timeOfDay;
      }
      return ReflectionPickSource.weekly;
  }
}

final reflectionNowProvider = Provider<DateTime>((ref) => DateTime.now());

final islamicDayProvider = Provider<IslamicDay>((ref) {
  return IslamicDay.fromDateTime(ref.watch(reflectionNowProvider));
});

final reflectionPickProvider = FutureProvider<ReflectionPick>((ref) async {
  final day = ref.watch(islamicDayProvider);
  var calendar = await ref.watch(calendarLensesProvider.future);
  var weekly = await ref.watch(weeklyRotationProvider.future);
  if (weekly.entries.isEmpty) {
    weekly = const ReflectionCatalog(
      version: 0,
      entries: kReflectionFallbackEntries,
    );
  }
  final all = [...calendar.entries, ...weekly.entries];
  final store = ReflectionHistoryStore();
  final ymd = day.hijri.ymdKey;
  final cached = await store.readToday();
  if (cached != null && cached.ymd == ymd) {
    for (final e in all) {
      if (e.id == cached.id) {
        return ReflectionPick(entry: e, source: _sourceFor(e));
      }
    }
  }
  final salt = await ref.watch(reflectionInstallSaltProvider.future);
  final recent = await store.readRecentIds();
  final pick = resolveReflectionPick(
    day: day,
    calendarEntries: calendar.entries,
    weeklyEntries: weekly.entries,
    seedSalt: salt,
    recentIds: recent,
  );
  final dayChanged = cached == null || cached.ymd != ymd;
  await store.writeToday(ymd: ymd, id: pick.entry.id);
  if (dayChanged) {
    await store.pushRecentId(pick.entry.id);
  }
  return pick;
});
