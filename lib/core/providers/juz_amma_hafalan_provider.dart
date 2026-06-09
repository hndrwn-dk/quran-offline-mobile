import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/juz_amma_hafalan.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _unitsAsset = 'assets/hafalan/juz_amma_units.json';
const _keyMode = 'juz_amma_hafalan_mode';
const _keyProgramStart = 'juz_amma_program_start';
const _keyFridayBannerDismissed = 'friday_setoran_banner_dismissed';
const _keyLibraryProgramCollapsed = 'library_juz_amma_program_collapsed';

final juzAmmaProgramProvider = FutureProvider<JuzAmmaProgram>((ref) async {
  final raw = await rootBundle.loadString(_unitsAsset);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return JuzAmmaProgram.fromJson(json);
});

final juzAmmaHafalanModeProvider =
    StateNotifierProvider<JuzAmmaHafalanModeNotifier, JuzAmmaHafalanMode>(
  (ref) => JuzAmmaHafalanModeNotifier(),
);

class JuzAmmaHafalanModeNotifier extends StateNotifier<JuzAmmaHafalanMode> {
  JuzAmmaHafalanModeNotifier() : super(JuzAmmaHafalanMode.program) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMode);
    if (raw == 'free') {
      state = JuzAmmaHafalanMode.free;
    }
  }

  Future<void> setMode(JuzAmmaHafalanMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyMode,
      mode == JuzAmmaHafalanMode.free ? 'free' : 'program',
    );
  }
}

final juzAmmaProgramStartProvider =
    StateNotifierProvider<JuzAmmaProgramStartNotifier, DateTime?>(
  (ref) => JuzAmmaProgramStartNotifier(),
);

class JuzAmmaProgramStartNotifier extends StateNotifier<DateTime?> {
  JuzAmmaProgramStartNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProgramStart);
    if (raw != null) {
      state = DateTime.tryParse(raw);
    }
  }

  Future<void> startProgram({DateTime? on}) async {
    final date = on ?? DateTime.now();
    final normalized = DateTime(date.year, date.month, date.day);
    state = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProgramStart, normalized.toIso8601String());
  }

  Future<void> resetProgram() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProgramStart);
  }
}

final juzAmmaMemorizedProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.read(databaseProvider);
  final rows = await db.getJuzAmmaMemorization();
  return rows.map((r) => '${r.surahId}:${r.ayahNo}').toSet();
});

final juzAmmaTodayTaskProvider = Provider<AsyncValue<HafalanDayTask>>((ref) {
  final programAsync = ref.watch(juzAmmaProgramProvider);
  final mode = ref.watch(juzAmmaHafalanModeProvider);
  final start = ref.watch(juzAmmaProgramStartProvider);

  return programAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (program) {
      if (mode == JuzAmmaHafalanMode.free) {
        return AsyncValue.data(HafalanDayTask.notStarted());
      }
      if (start == null) {
        return AsyncValue.data(HafalanDayTask.notStarted());
      }
      return AsyncValue.data(
        resolveHafalanDay(
          now: DateTime.now(),
          programStart: start,
          program: program,
        ),
      );
    },
  );
});

class JuzAmmaProgressSummary {
  final int memorizedAyahs;
  final int totalAyahs;
  final int completedUnits;
  final int totalUnits;

  const JuzAmmaProgressSummary({
    required this.memorizedAyahs,
    required this.totalAyahs,
    required this.completedUnits,
    required this.totalUnits,
  });

  double get ayahFraction =>
      totalAyahs == 0 ? 0 : memorizedAyahs / totalAyahs;

  double get unitFraction =>
      totalUnits == 0 ? 0 : completedUnits / totalUnits;
}

final juzAmmaProgressSummaryProvider =
    FutureProvider<JuzAmmaProgressSummary>((ref) async {
  final program = await ref.watch(juzAmmaProgramProvider.future);
  final memorized = await ref.watch(juzAmmaMemorizedProvider.future);

  var completedUnits = 0;
  for (final unit in program.units) {
    var all = true;
    for (var a = unit.from; a <= unit.to; a++) {
      if (!memorized.contains('${unit.surah}:$a')) {
        all = false;
        break;
      }
    }
    if (all) completedUnits++;
  }

  return JuzAmmaProgressSummary(
    memorizedAyahs: memorized.length,
    totalAyahs: JuzAmmaProgram.totalAyahs,
    completedUnits: completedUnits,
    totalUnits: program.units.length,
  );
});

Future<void> toggleJuzAmmaAyahMemorized(
  WidgetRef ref,
  int surahId,
  int ayahNo,
  bool memorized,
) async {
  if (!isJuzAmmaSurah(surahId)) return;
  final db = ref.read(databaseProvider);
  await db.setAyahMemorized(surahId, ayahNo, memorized);
  ref.invalidate(juzAmmaMemorizedProvider);
  ref.invalidate(juzAmmaProgressSummaryProvider);
  ref.invalidate(fridaySetoranQueueProvider);
}

Future<bool> isJuzAmmaAyahMemorized(
  WidgetRef ref,
  int surahId,
  int ayahNo,
) async {
  final set = await ref.read(juzAmmaMemorizedProvider.future);
  return set.contains('$surahId:$ayahNo');
}

class FridaySetoranEntry {
  final JuzAmmaUnit unit;
  final bool isDone;

  const FridaySetoranEntry({required this.unit, required this.isDone});
}

final currentFridayKeyProvider = Provider<String>((ref) {
  return fridayKeyFor(DateTime.now());
});

final fridaySetoranQueueProvider =
    FutureProvider<List<FridaySetoranEntry>>((ref) async {
  final now = DateTime.now();
  if (now.weekday != DateTime.friday) return [];

  final fridayKey = fridayKeyFor(now);
  final db = ref.read(databaseProvider);
  final doneLogs = await db.getSetoranLogsForFriday(fridayKey);
  final doneKeys = doneLogs.map((l) => l.itemKey).toSet();

  final mode = ref.watch(juzAmmaHafalanModeProvider);
  final program = await ref.watch(juzAmmaProgramProvider.future);
  final start = ref.watch(juzAmmaProgramStartProvider);

  final rows = await db.getJuzAmmaMemorization();
  final memorizedKeys = rows.map((r) => '${r.surahId}:${r.ayahNo}').toSet();
  final rowTuples = rows
      .map(
        (r) => (
          surahId: r.surahId,
          ayahNo: r.ayahNo,
          completedAt: r.completedAt,
        ),
      )
      .toList();

  var units = <JuzAmmaUnit>[];
  if (mode == JuzAmmaHafalanMode.program && start != null) {
    units = resolveFridaySetoranQueue(
      now: now,
      programStart: start,
      program: program,
    );
  }

  if (units.isEmpty) {
    units = resolveFridaySetoranQueueFromMemorized(
      now: now,
      rows: rowTuples,
    );
  }

  if (units.isEmpty) {
    if (mode == JuzAmmaHafalanMode.program) {
      units = resolveFridaySetoranQueueFromPartialProgram(
        program: program,
        memorizedKeys: memorizedKeys,
      );
    } else {
      units = resolveFridaySetoranQueueFromAllMemorized(
        memorizedKeys: memorizedKeys,
      );
    }
  }

  return units
      .map(
        (u) => FridaySetoranEntry(
          unit: u,
          isDone: doneKeys.contains(setoranItemKey(u)),
        ),
      )
      .toList();
});

final fridaySetoranBannerVisibleProvider = Provider<bool>((ref) {
  final now = DateTime.now();
  if (now.weekday != DateTime.friday) return false;

  final dismissed = ref.watch(fridayBannerDismissedProvider);
  if (dismissed) return false;

  final queue = ref.watch(fridaySetoranQueueProvider);
  return queue.maybeWhen(
    data: (items) {
      if (items.isEmpty) return false;
      return items.any((e) => !e.isDone);
    },
    orElse: () => false,
  );
});

final fridayBannerDismissedProvider =
    StateNotifierProvider<FridayBannerDismissedNotifier, bool>(
  (ref) => FridayBannerDismissedNotifier(),
);

class FridayBannerDismissedNotifier extends StateNotifier<bool> {
  FridayBannerDismissedNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyFridayBannerDismissed:${fridayKeyFor(DateTime.now())}';
    state = prefs.getBool(key) ?? false;
  }

  Future<void> dismiss() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyFridayBannerDismissed:${fridayKeyFor(DateTime.now())}';
    await prefs.setBool(key, true);
  }
}

Future<void> markFridaySetoranDone(WidgetRef ref, JuzAmmaUnit unit) async {
  final fridayKey = fridayKeyFor(DateTime.now());
  final db = ref.read(databaseProvider);
  await db.markSetoranItemDone(
    fridayKey: fridayKey,
    itemKey: setoranItemKey(unit),
    surahId: unit.surah,
    fromAyah: unit.from,
    toAyah: unit.to,
  );
  ref.invalidate(fridaySetoranQueueProvider);
}

final libraryJuzAmmaCollapsedProvider =
    StateNotifierProvider<LibraryJuzAmmaCollapsedNotifier, bool>(
  (ref) => LibraryJuzAmmaCollapsedNotifier(),
);

class LibraryJuzAmmaCollapsedNotifier extends StateNotifier<bool> {
  LibraryJuzAmmaCollapsedNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyLibraryProgramCollapsed) ?? false;
  }

  Future<void> setCollapsed(bool collapsed) async {
    state = collapsed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLibraryProgramCollapsed, collapsed);
  }

  Future<void> toggle() => setCollapsed(!state);
}

Future<void> unmarkFridaySetoran(WidgetRef ref, JuzAmmaUnit unit) async {
  final fridayKey = fridayKeyFor(DateTime.now());
  final db = ref.read(databaseProvider);
  await db.unmarkSetoranItem(fridayKey, setoranItemKey(unit));
  ref.invalidate(fridaySetoranQueueProvider);
}
