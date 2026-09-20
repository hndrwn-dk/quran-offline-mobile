@Tags(['distribution'])
library;

// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

const _text = LocalizedText(id: 't', en: 't', zh: 't', ja: 't');

ReflectionLensEntry lens({
  required String id,
  required String badgeKey,
  int sort = 0,
  int priority = 0,
  ReflectionTrigger? trigger,
}) {
  return ReflectionLensEntry(
    id: id,
    sort: sort,
    priority: priority,
    badgeKey: badgeKey,
    title: _text,
    summary: _text,
    reflection: _text,
    ayahRefs: const [DuaAyahRef(surah: 1, from: 1, to: 1)],
    trigger: trigger,
  );
}

List<ReflectionLensEntry> calendarCatalog() => [
      lens(
        id: 'ramadan_quran',
        badgeKey: 'ramadan',
        priority: 80,
        sort: 10,
        trigger: const ReflectionTrigger(type: 'hijri_month', hijriMonth: 9),
      ),
      lens(
        id: 'ramadan_laylat',
        badgeKey: 'ramadan',
        priority: 85,
        sort: 15,
        trigger: const ReflectionTrigger(
          type: 'hijri_day',
          hijriMonth: 9,
          hijriDay: 21,
        ),
      ),
      lens(
        id: 'muharram_new_year',
        badgeKey: 'hijrah',
        priority: 70,
        sort: 20,
        trigger: const ReflectionTrigger(
          type: 'hijri_day',
          hijriMonth: 1,
          hijriDay: 1,
        ),
      ),
      lens(
        id: 'jumat_kahf',
        badgeKey: 'friday',
        priority: 50,
        sort: 30,
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      ),
      lens(
        id: 'jumat_shalat',
        badgeKey: 'friday',
        priority: 45,
        sort: 35,
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      ),
      lens(
        id: 'pagi_syukur',
        badgeKey: 'morning',
        priority: 15,
        sort: 40,
        trigger: const ReflectionTrigger(
          type: 'time_of_day',
          period: 'morning',
        ),
      ),
      lens(
        id: 'malam_berlindung',
        badgeKey: 'evening',
        priority: 15,
        sort: 50,
        trigger: const ReflectionTrigger(
          type: 'time_of_day',
          period: 'evening',
        ),
      ),
      lens(
        id: 'sabtu_istighfar',
        badgeKey: 'weekly',
        priority: 10,
        sort: 60,
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 6),
      ),
    ];

List<ReflectionLensEntry> weeklyCatalog() => [
      for (var i = 1; i <= 19; i++)
        lens(
          id: 'week_${i.toString().padLeft(2, '0')}',
          badgeKey: 'weekly',
          sort: i * 10,
        ),
    ];

List<String> allFixtureIds() => [
      ...calendarCatalog().map((e) => e.id),
      ...weeklyCatalog().map((e) => e.id),
    ];

class SimDay {
  final String id;
  final ReflectionTier tier;
  const SimDay(this.id, this.tier);

  @override
  bool operator ==(Object other) =>
      other is SimDay && other.id == id && other.tier == tier;

  @override
  int get hashCode => Object.hash(id, tier);
}

List<SimDay> simulate({required int hour, String salt = 'test-salt'}) {
  final calendar = calendarCatalog();
  final weekly = weeklyCatalog();
  final ids = <SimDay>[];
  final recent = <String>[];
  final start = DateTime(2026, 1, 1, hour);
  final end = DateTime(2026, 12, 31, hour);
  for (var clock = start;
      !clock.isAfter(end);
      clock = DateTime(
    clock.year,
    clock.month,
    clock.day + 1,
    hour,
  )) {
    final islamic = IslamicDay.fromDateTime(clock);
    final pick = resolveReflectionPick(
      day: islamic,
      calendarEntries: calendar,
      weeklyEntries: weekly,
      seedSalt: salt,
      recentIds: List<String>.from(recent),
    );
    ids.add(SimDay(pick.entry.id, pick.entry.tier));
    recent.insert(0, pick.entry.id);
  }
  return ids;
}

Map<String, int> countsOf(List<SimDay> days) {
  final counts = <String, int>{};
  for (final day in days) {
    counts[day.id] = (counts[day.id] ?? 0) + 1;
  }
  return counts;
}

bool _isOccasion(ReflectionTier tier) =>
    tier == ReflectionTier.fixedDate || tier == ReflectionTier.season;

int longestNonOccasionRun(List<SimDay> days) {
  var best = 0;
  var current = 0;
  String? currentId;
  for (final day in days) {
    if (_isOccasion(day.tier)) {
      current = 0;
      currentId = null;
      continue;
    }
    if (day.id == currentId) {
      current++;
    } else {
      current = 1;
      currentId = day.id;
    }
    if (current > best) best = current;
  }
  return best;
}

int longestOccasionRun(List<SimDay> days) {
  var best = 0;
  var current = 0;
  String? currentId;
  for (final day in days) {
    if (!_isOccasion(day.tier)) {
      current = 0;
      currentId = null;
      continue;
    }
    if (day.id == currentId) {
      current++;
    } else {
      current = 1;
      currentId = day.id;
    }
    if (current > best) best = current;
  }
  return best;
}

void printPass(int hour, List<SimDay> days) {
  final total = days.length;
  final counts = countsOf(days).entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('hour=$hour total=$total');
  print('counts:');
  for (final e in counts) {
    final pct = (e.value / total * 100).toStringAsFixed(1);
    print('  ${e.key}: ${e.value} ($pct%)');
  }
  final seen = days.map((d) => d.id).toSet();
  final zeros = allFixtureIds().where((id) => !seen.contains(id)).toList();
  print('zero: ${zeros.isEmpty ? '(none)' : zeros.join(', ')}');
  print('distinct: ${seen.length}');
  print('longest_run_non_occasion: ${longestNonOccasionRun(days)}');
  print('longest_run_occasion: ${longestOccasionRun(days)}');
  var fridayKahf = 0;
  var fridayShalat = 0;
  var fridayOther = 0;
  var fridayCount = 0;
  var saturdayCount = 0;
  var saturdayIstighfar = 0;
  final start = DateTime(2026, 1, 1);
  for (var i = 0; i < days.length; i++) {
    final clock = DateTime(start.year, start.month, start.day + i, hour);
    final islamic = IslamicDay.fromDateTime(clock);
    if (islamic.weekday == DateTime.friday) {
      fridayCount++;
      if (days[i].id == 'jumat_kahf') {
        fridayKahf++;
      } else if (days[i].id == 'jumat_shalat') {
        fridayShalat++;
      } else {
        fridayOther++;
      }
    }
    if (islamic.weekday == DateTime.saturday) {
      saturdayCount++;
      if (days[i].id == 'sabtu_istighfar') saturdayIstighfar++;
    }
  }
  print(
    'fridays: n=$fridayCount jumat_kahf=$fridayKahf '
    'jumat_shalat=$fridayShalat other=$fridayOther',
  );
  print('saturdays: n=$saturdayCount sabtu_istighfar=$saturdayIstighfar');
}

void main() {
  test('prints 365-day reflection distribution', () {
    print(
      'note: weighted draw + recent ring; seed=test-salt; maghrib hour='
      '$kMaghribRolloverHour',
    );
    final morning = simulate(hour: 7);
    printPass(7, morning);
    printPass(14, simulate(hour: 14));
    printPass(20, simulate(hour: 20));
    final morningAgain = simulate(hour: 7);
    var same = morning.length == morningAgain.length;
    if (same) {
      for (var i = 0; i < morning.length; i++) {
        if (morning[i] != morningAgain[i]) {
          same = false;
          break;
        }
      }
    }
    print('reproducible: $same');
    expect(same, isTrue);
    final evening = simulate(hour: 20);
    final pagiShare = morning.where((d) => d.id == 'pagi_syukur').length / 365;
    expect(morning.map((d) => d.id).toSet().length, greaterThanOrEqualTo(15));
    // Higher tiers win first; pagi_syukur (ambient, weight 3) competes with
    // 19 always-eligible week_* entries (weight 1 each), so share is ~0.066.
    expect(pagiShare, inInclusiveRange(0.05, 0.08));
    expect(longestNonOccasionRun(morning), lessThanOrEqualTo(5));
    expect(
      evening.where((d) => d.id == 'ramadan_quran').length,
      greaterThanOrEqualTo(25),
    );
    expect(morning.where((d) => d.id == 'ramadan_laylat'), isNotEmpty);
    expect(morning.where((d) => d.id == 'muharram_new_year'), isNotEmpty);
    var fridayKahf = 0;
    var fridayShalat = 0;
    var fridayCount = 0;
    var saturdayCount = 0;
    var saturdayIstighfar = 0;
    final start = DateTime(2026, 1, 1);
    for (var i = 0; i < morning.length; i++) {
      final clock = DateTime(start.year, start.month, start.day + i, 7);
      final islamic = IslamicDay.fromDateTime(clock);
      if (islamic.weekday == DateTime.friday) {
        fridayCount++;
        if (morning[i].id == 'jumat_kahf') fridayKahf++;
        if (morning[i].id == 'jumat_shalat') fridayShalat++;
      }
      if (islamic.weekday == DateTime.saturday) {
        saturdayCount++;
        if (morning[i].id == 'sabtu_istighfar') saturdayIstighfar++;
      }
    }
    expect(fridayKahf, greaterThan(0));
    expect(fridayShalat, greaterThan(0));
    expect(fridayKahf + fridayShalat, greaterThanOrEqualTo(45));
    expect(fridayCount, 52);
    expect(
      saturdayIstighfar / saturdayCount,
      inInclusiveRange(0.50, 0.80),
    );
  }, tags: ['distribution']);
}
