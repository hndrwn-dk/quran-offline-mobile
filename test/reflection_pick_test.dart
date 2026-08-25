import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_fallback.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

const _text = LocalizedText(id: 't', en: 't', zh: 't', ja: 't');

ReflectionLensEntry lens({
  required String id,
  int sort = 0,
  int priority = 0,
  String badgeKey = 'weekly',
  ReflectionTrigger? trigger,
  List<HijriDay> forbidOn = const [],
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
    forbidOn: forbidOn,
  );
}

List<ReflectionLensEntry> get calendar => [
      lens(
        id: 'ramadan_quran',
        priority: 80,
        badgeKey: 'ramadan',
        trigger: const ReflectionTrigger(type: 'hijri_month', hijriMonth: 9),
      ),
      lens(
        id: 'ramadan_laylat',
        priority: 85,
        badgeKey: 'ramadan',
        trigger: const ReflectionTrigger(
          type: 'hijri_day',
          hijriMonth: 9,
          hijriDay: 21,
        ),
      ),
      lens(
        id: 'muharram_new_year',
        priority: 70,
        badgeKey: 'hijrah',
        trigger: const ReflectionTrigger(
          type: 'hijri_day',
          hijriMonth: 1,
          hijriDay: 1,
        ),
      ),
      lens(
        id: 'jumat_kahf',
        priority: 50,
        badgeKey: 'friday',
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      ),
      lens(
        id: 'jumat_shalat',
        priority: 45,
        badgeKey: 'friday',
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      ),
      lens(
        id: 'pagi_syukur',
        priority: 15,
        badgeKey: 'morning',
        trigger: const ReflectionTrigger(
          type: 'time_of_day',
          period: 'morning',
        ),
      ),
      lens(
        id: 'malam_berlindung',
        priority: 15,
        badgeKey: 'evening',
        trigger: const ReflectionTrigger(
          type: 'time_of_day',
          period: 'evening',
        ),
      ),
      lens(
        id: 'sabtu_istighfar',
        priority: 10,
        badgeKey: 'weekly',
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 6),
      ),
    ];

List<ReflectionLensEntry> get weekly => [
      lens(id: 'week_a', sort: 10),
      lens(id: 'week_b', sort: 20),
    ];

ReflectionPick pick(
  DateTime now, {
  String salt = 's',
  List<String> recentIds = const [],
}) {
  return resolveReflectionPick(
    day: IslamicDay.fromDateTime(now),
    calendarEntries: calendar,
    weeklyEntries: weekly,
    seedSalt: salt,
    recentIds: recentIds,
  );
}

void main() {
  test('derived tiers match trigger types', () {
    expect(calendar.firstWhere((e) => e.id == 'ramadan_laylat').tier,
        ReflectionTier.fixedDate);
    expect(calendar.firstWhere((e) => e.id == 'ramadan_quran').tier,
        ReflectionTier.season);
    expect(calendar.firstWhere((e) => e.id == 'jumat_kahf').tier,
        ReflectionTier.weekday);
    expect(calendar.firstWhere((e) => e.id == 'pagi_syukur').tier,
        ReflectionTier.ambient);
    expect(weekly.first.tier, ReflectionTier.ambient);
    expect(calendar.firstWhere((e) => e.id == 'pagi_syukur').weight, 3);
    expect(calendar.firstWhere((e) => e.id == 'jumat_kahf').weight, 1);
  });

  test('Thursday 20:00 is Friday weekday pool, not locked to Kahf', () {
    final now = DateTime(2026, 8, 20, 20);
    expect(now.weekday, DateTime.thursday);
    expect(IslamicDay.fromDateTime(now).weekday, DateTime.friday);
    final ids = <String>{};
    for (var i = 0; i < 40; i++) {
      ids.add(pick(now, salt: 'thu-$i').entry.id);
    }
    expect(ids, containsAll(['jumat_kahf', 'jumat_shalat']));
  });

  test('Ramadan evening is exclusive ramadan_quran', () {
    const day = IslamicDay(
      hijri: HijriDate(year: 1447, month: 9, day: 10),
      weekday: DateTime.tuesday,
      period: TimeOfDayPeriod.evening,
    );
    expect(
      resolveReflectionPick(
        day: day,
        calendarEntries: calendar,
        weeklyEntries: weekly,
        seedSalt: 'r',
        recentIds: const ['ramadan_quran', 'malam_berlindung'],
      ).entry.id,
      'ramadan_quran',
    );
  });

  test('Ramadan 21 is exclusive laylat', () {
    expect(
      resolveReflectionPick(
        day: const IslamicDay(
          hijri: HijriDate(year: 1447, month: 9, day: 21),
          weekday: DateTime.friday,
          period: TimeOfDayPeriod.evening,
        ),
        calendarEntries: calendar,
        weeklyEntries: weekly,
        seedSalt: 'laylat',
        recentIds: const ['ramadan_laylat', 'jumat_kahf'],
      ).entry.id,
      'ramadan_laylat',
    );
  });

  test('1 Muharram is exclusive even on Friday', () {
    expect(
      resolveReflectionPick(
        day: const IslamicDay(
          hijri: HijriDate(year: 1448, month: 1, day: 1),
          weekday: DateTime.friday,
          period: TimeOfDayPeriod.morning,
        ),
        calendarEntries: calendar,
        weeklyEntries: weekly,
        seedSalt: 'm',
        recentIds: const ['muharram_new_year', 'jumat_kahf'],
      ).entry.id,
      'muharram_new_year',
    );
  });

  test('ordinary morning ambient includes pagi and weekly', () {
    final ids = <String>{};
    for (var i = 0; i < 60; i++) {
      ids.add(pick(DateTime(2026, 8, 25, 7), salt: 'am-$i').entry.id);
    }
    expect(ids, contains('pagi_syukur'));
    expect(ids, contains('week_a'));
    expect(ids, contains('week_b'));
    expect(ids, isNot(contains('malam_berlindung')));
  });

  test('same salt and ymd reproduce', () {
    final a = pick(DateTime(2026, 8, 25, 7), salt: 'same');
    final b = pick(DateTime(2026, 8, 25, 10), salt: 'same');
    expect(a.entry.id, b.entry.id);
  });

  test('recentIds drops a match unless it empties the pool', () {
    final ids = <String>{};
    for (var i = 0; i < 30; i++) {
      ids.add(
        resolveReflectionPick(
          day: const IslamicDay(
            hijri: HijriDate(year: 1448, month: 2, day: 27),
            weekday: DateTime.friday,
            period: TimeOfDayPeriod.morning,
          ),
          calendarEntries: calendar,
          weeklyEntries: weekly,
          seedSalt: 'x-$i',
          recentIds: const ['jumat_kahf'],
        ).entry.id,
      );
    }
    expect(ids, isNot(contains('jumat_kahf')));
    expect(ids, contains('jumat_shalat'));
  });

  test('season pool does not bleed or use the ring', () {
    expect(
      resolveReflectionPick(
        day: const IslamicDay(
          hijri: HijriDate(year: 1447, month: 9, day: 10),
          weekday: DateTime.wednesday,
          period: TimeOfDayPeriod.morning,
        ),
        calendarEntries: calendar,
        weeklyEntries: weekly,
        seedSalt: 'bleed',
        recentIds: const ['ramadan_quran', 'pagi_syukur'],
      ).entry.id,
      'ramadan_quran',
    );
  });

  test('reflectionRecentCap clamps eligible minus one to 1..5', () {
    expect(reflectionRecentCap(20), 5);
    expect(reflectionRecentCap(2), 1);
    expect(reflectionRecentCap(1), 1);
    expect(reflectionRecentCap(8), 5);
  });

  test('forbidOn drops an entry', () {
    final blocked = lens(
      id: 'blocked_kahf',
      trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      forbidOn: const [HijriDay(month: 2, day: 27)],
    );
    final p = resolveReflectionPick(
      day: const IslamicDay(
        hijri: HijriDate(year: 1448, month: 2, day: 27),
        weekday: DateTime.friday,
        period: TimeOfDayPeriod.morning,
      ),
      calendarEntries: [
        blocked,
        calendar.firstWhere((e) => e.id == 'jumat_shalat')
      ],
      weeklyEntries: const [],
      seedSalt: 'f',
    );
    expect(p.entry.id, 'jumat_shalat');
  });

  test('fallback entries all have ayahRefs', () {
    expect(kReflectionFallbackEntries, hasLength(3));
    expect(
      kReflectionFallbackEntries.map((e) => e.id).toList(),
      ['fallback_fatihah', 'fallback_ikhlas', 'fallback_asr'],
    );
    const expectedRefs = [
      (1, 1, 7),
      (112, 1, 4),
      (103, 1, 3),
    ];
    for (var i = 0; i < kReflectionFallbackEntries.length; i++) {
      final e = kReflectionFallbackEntries[i];
      expect(e.ayahRefs, isNotEmpty);
      expect(e.trigger, isNull);
      expect(e.tier, ReflectionTier.ambient);
      final ref = e.ayahRefs.first;
      expect(ref.surah, expectedRefs[i].$1);
      expect(ref.from, expectedRefs[i].$2);
      expect(ref.to, expectedRefs[i].$3);
    }
  });

  test('thin weekday pool borrows at most three ambient', () {
    final ambients = [
      for (var i = 0; i < 10; i++) lens(id: 'amb_$i', sort: 100 + i),
    ];
    const day = IslamicDay(
      hijri: HijriDate(year: 1448, month: 2, day: 27),
      weekday: DateTime.friday,
      period: TimeOfDayPeriod.morning,
    );
    var weekdayHits = 0;
    final seenAmbient = <String>{};
    const n = 200;
    for (var i = 0; i < n; i++) {
      final id = resolveReflectionPick(
        day: day,
        calendarEntries: [
          calendar.firstWhere((e) => e.id == 'jumat_kahf'),
          calendar.firstWhere((e) => e.id == 'jumat_shalat'),
        ],
        weeklyEntries: ambients,
        seedSalt: 'thin-$i',
      ).entry.id;
      if (id == 'jumat_kahf' || id == 'jumat_shalat') {
        weekdayHits++;
      } else {
        seenAmbient.add(id);
      }
    }
    expect(weekdayHits / n, inInclusiveRange(0.55, 0.85));
    expect(seenAmbient, isNotEmpty);
  });

  test('empty catalogs resolve using fallback weekly entries', () {
    final p = resolveReflectionPick(
      day: IslamicDay.fromDateTime(DateTime(2026, 8, 25, 14)),
      calendarEntries: const [],
      weeklyEntries: kReflectionFallbackEntries,
      seedSalt: 'fb',
    );
    expect(p.source, ReflectionPickSource.weekly);
    expect(
      p.entry.id,
      isIn(['fallback_fatihah', 'fallback_ikhlas', 'fallback_asr']),
    );
  });
}
