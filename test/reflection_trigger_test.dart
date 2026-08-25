import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';

void main() {
  const hijri = HijriDate(year: 1447, month: 9, day: 25);
  final now = DateTime(2026, 3, 15, 10);

  test('hijri_day with dayFrom/dayTo matches inclusive range', () {
    final t = ReflectionTrigger(
      type: 'hijri_day',
      hijriMonth: 9,
      hijriDayFrom: 21,
      hijriDayTo: 30,
    );
    expect(t.matches(now, hijri), isTrue);
    expect(
      t.matches(now, const HijriDate(year: 1447, month: 9, day: 20)),
      isFalse,
    );
  });

  test('hijri_day with only day matches that day', () {
    final t = ReflectionTrigger(
      type: 'hijri_day',
      hijriMonth: 9,
      hijriDay: 21,
    );
    expect(
      t.matches(now, const HijriDate(year: 1447, month: 9, day: 21)),
      isTrue,
    );
    expect(
      t.matches(now, const HijriDate(year: 1447, month: 9, day: 22)),
      isFalse,
    );
  });

  test('slots restricts appliesInSlot', () {
    final t = ReflectionTrigger(
      type: 'hijri_day',
      hijriMonth: 9,
      hijriDay: 21,
      slots: const [ReflectionSlot.evening],
    );
    expect(t.appliesInSlot(ReflectionSlot.evening), isTrue);
    expect(t.appliesInSlot(ReflectionSlot.morning), isFalse);
  });

  test('fromJson reads dayFrom dayTo slots', () {
    final t = ReflectionTrigger.fromJson({
      'type': 'hijri_day',
      'month': 9,
      'dayFrom': 21,
      'dayTo': 30,
      'slots': ['evening'],
    });
    expect(t.hijriDayFrom, 21);
    expect(t.hijriDayTo, 30);
    expect(t.slots, [ReflectionSlot.evening]);
  });
}
