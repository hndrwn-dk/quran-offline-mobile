import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';

void main() {
  test('Ramadan lens beats Friday lens on Ramadan Friday', () {
    final calendar = [
      ReflectionLensEntry(
        id: 'friday',
        sort: 1,
        priority: 50,
        badgeKey: 'friday',
        title: const LocalizedText(id: 'f', en: 'f', zh: 'f', ja: 'f'),
        summary: const LocalizedText(id: 'f', en: 'f', zh: 'f', ja: 'f'),
        reflection: const LocalizedText(id: 'f', en: 'f', zh: 'f', ja: 'f'),
        ayahRefs: const [],
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      ),
      ReflectionLensEntry(
        id: 'ramadan',
        sort: 2,
        priority: 80,
        badgeKey: 'ramadan',
        title: const LocalizedText(id: 'r', en: 'r', zh: 'r', ja: 'r'),
        summary: const LocalizedText(id: 'r', en: 'r', zh: 'r', ja: 'r'),
        reflection: const LocalizedText(id: 'r', en: 'r', zh: 'r', ja: 'r'),
        ayahRefs: const [],
        trigger: const ReflectionTrigger(type: 'hijri_month', hijriMonth: 9),
      ),
    ];
    final weekly = [
      ReflectionLensEntry(
        id: 'week',
        sort: 1,
        priority: 0,
        badgeKey: 'weekly',
        title: const LocalizedText(id: 'w', en: 'w', zh: 'w', ja: 'w'),
        summary: const LocalizedText(id: 'w', en: 'w', zh: 'w', ja: 'w'),
        reflection: const LocalizedText(id: 'w', en: 'w', zh: 'w', ja: 'w'),
        ayahRefs: const [],
      ),
    ];

    final friday = DateTime(2024, 3, 15, 10);
    expect(friday.weekday, DateTime.friday);
    expect(HijriDate.fromGregorian(friday).month, 9);

    final pick = resolveReflectionPick(
      now: friday,
      calendarEntries: calendar,
      weeklyEntries: weekly,
    );

    expect(pick.entry.id, 'ramadan');
    expect(pick.source, ReflectionPickSource.calendar);
  });

  test('weekly rotation is used when no calendar trigger matches', () {
    final weekly = [
      ReflectionLensEntry(
        id: 'a',
        sort: 10,
        priority: 0,
        badgeKey: 'weekly',
        title: const LocalizedText(id: 'a', en: 'a', zh: 'a', ja: 'a'),
        summary: const LocalizedText(id: 'a', en: 'a', zh: 'a', ja: 'a'),
        reflection: const LocalizedText(id: 'a', en: 'a', zh: 'a', ja: 'a'),
        ayahRefs: const [],
      ),
      ReflectionLensEntry(
        id: 'b',
        sort: 20,
        priority: 0,
        badgeKey: 'weekly',
        title: const LocalizedText(id: 'b', en: 'b', zh: 'b', ja: 'b'),
        summary: const LocalizedText(id: 'b', en: 'b', zh: 'b', ja: 'b'),
        reflection: const LocalizedText(id: 'b', en: 'b', zh: 'b', ja: 'b'),
        ayahRefs: const [],
      ),
    ];

    final pick = resolveReflectionPick(
      now: DateTime(2025, 1, 8, 14),
      calendarEntries: const [],
      weeklyEntries: weekly,
    );

    expect(pick.source, ReflectionPickSource.weekly);
    expect(pick.entry.id, isIn(['a', 'b']));
  });
}
