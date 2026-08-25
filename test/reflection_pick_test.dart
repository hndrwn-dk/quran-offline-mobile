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

const ordinaryHijri = HijriDate(year: 1448, month: 2, day: 27);

ReflectionPick pick(DateTime now, {HijriDate hijri = ordinaryHijri}) {
  return resolveReflectionPick(
    now: now,
    hijri: hijri,
    calendarEntries: calendar,
    weeklyEntries: weekly,
  );
}

void main() {
  test('Thursday 19:00 is malam Jumat Kahf', () {
    final now = DateTime(2026, 8, 20, 19);
    expect(now.weekday, DateTime.thursday);
    expect(pick(now).entry.id, 'jumat_kahf');
  });

  test('Friday 19:00 is malam_berlindung not Kahf', () {
    final now = DateTime(2026, 8, 21, 19);
    expect(now.weekday, DateTime.friday);
    expect(pick(now).entry.id, 'malam_berlindung');
  });

  test('Saturday 19:00 is malam_berlindung not istighfar', () {
    final now = DateTime(2026, 8, 22, 19);
    expect(now.weekday, DateTime.saturday);
    expect(pick(now).entry.id, 'malam_berlindung');
  });

  test('Friday 08:00 is Kahf', () {
    expect(pick(DateTime(2026, 8, 21, 8)).entry.id, 'jumat_kahf');
  });

  test('Friday 13:00 is jumat_shalat', () {
    expect(pick(DateTime(2026, 8, 21, 13)).entry.id, 'jumat_shalat');
  });

  test('Saturday 08:00 is sabtu_istighfar', () {
    expect(pick(DateTime(2026, 8, 22, 8)).entry.id, 'sabtu_istighfar');
  });

  test('Ramadan Friday morning beats Kahf', () {
    final now = DateTime(2026, 8, 21, 8);
    final hijri = HijriDate(year: 1447, month: 9, day: 10);
    expect(pick(now, hijri: hijri).entry.id, 'ramadan_quran');
  });

  test('ordinary morning is pagi_syukur', () {
    expect(pick(DateTime(2026, 8, 25, 7)).entry.id, 'pagi_syukur');
  });

  test('ordinary midday uses weekly rotation', () {
    final p = pick(DateTime(2026, 8, 25, 14));
    expect(p.source, ReflectionPickSource.weekly);
    expect(p.entry.id, isIn(['week_a', 'week_b']));
  });

  test('same midday date is stable', () {
    final a = pick(DateTime(2026, 8, 25, 14));
    final b = pick(DateTime(2026, 8, 25, 16));
    expect(a.entry.id, b.entry.id);
  });

  test('two consecutive local midday dates can differ', () {
    final a = pick(DateTime(2026, 8, 25, 14));
    final b = pick(DateTime(2026, 8, 26, 14));
    expect(a.entry.id, isNot(b.entry.id));
    expect({a.entry.id, b.entry.id}, unorderedEquals(['week_a', 'week_b']));
  });

  test('Thursday 19:00 Hijri 9/21 is ramadan_laylat not Kahf', () {
    final now = DateTime(2026, 8, 20, 19);
    final hijri = HijriDate(year: 1447, month: 9, day: 21);
    expect(now.weekday, DateTime.thursday);
    expect(pick(now, hijri: hijri).entry.id, 'ramadan_laylat');
  });

  test('Friday 19:00 Hijri 9/21 is ramadan_laylat not malam_berlindung', () {
    final now = DateTime(2026, 8, 21, 19);
    final hijri = HijriDate(year: 1447, month: 9, day: 21);
    expect(now.weekday, DateTime.friday);
    expect(pick(now, hijri: hijri).entry.id, 'ramadan_laylat');
  });

  test('hijri_day 1 Muharram beats morning', () {
    final hijri = HijriDate(year: 1448, month: 1, day: 1);
    expect(
      pick(DateTime(2026, 8, 25, 7), hijri: hijri).entry.id,
      'muharram_new_year',
    );
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
      expect(e.title.id, isNotEmpty);
      expect(e.title.en, isNotEmpty);
      expect(e.title.zh, isNotEmpty);
      expect(e.title.ja, isNotEmpty);
      expect(e.summary.id, isNotEmpty);
      expect(e.summary.en, isNotEmpty);
      expect(e.summary.zh, isNotEmpty);
      expect(e.summary.ja, isNotEmpty);
      expect(e.reflection.id, isNotEmpty);
      expect(e.reflection.en, isNotEmpty);
      expect(e.reflection.zh, isNotEmpty);
      expect(e.reflection.ja, isNotEmpty);
      final ref = e.ayahRefs.first;
      expect(ref.surah, expectedRefs[i].$1);
      expect(ref.from, expectedRefs[i].$2);
      expect(ref.to, expectedRefs[i].$3);
      final copy = [
        e.title.id,
        e.title.en,
        e.title.zh,
        e.title.ja,
        e.summary.id,
        e.summary.en,
        e.summary.zh,
        e.summary.ja,
        e.reflection.id,
        e.reflection.en,
        e.reflection.zh,
        e.reflection.ja,
      ].join();
      expect(
        copy.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)),
        isFalse,
      );
    }
  });

  test('empty catalogs resolve using fallback weekly entries', () {
    final p = resolveReflectionPick(
      now: DateTime(2026, 8, 25, 14),
      hijri: ordinaryHijri,
      calendarEntries: const [],
      weeklyEntries: kReflectionFallbackEntries,
    );
    expect(p.source, ReflectionPickSource.weekly);
    expect(
      p.entry.id,
      isIn(['fallback_fatihah', 'fallback_ikhlas', 'fallback_asr']),
    );
  });
}
