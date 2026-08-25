import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';

IslamicDay dayFor({
  required HijriDate hijri,
  int weekday = DateTime.monday,
  TimeOfDayPeriod? period,
}) {
  return IslamicDay(hijri: hijri, weekday: weekday, period: period);
}

void main() {
  const hijri = HijriDate(year: 1447, month: 9, day: 25);

  test('hijri_day with dayFrom/dayTo matches inclusive range', () {
    final t = ReflectionTrigger(
      type: 'hijri_day',
      hijriMonth: 9,
      hijriDayFrom: 21,
      hijriDayTo: 30,
    );
    expect(t.matches(dayFor(hijri: hijri)), isTrue);
    expect(
      t.matches(
        dayFor(hijri: const HijriDate(year: 1447, month: 9, day: 20)),
      ),
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
      t.matches(
        dayFor(hijri: const HijriDate(year: 1447, month: 9, day: 21)),
      ),
      isTrue,
    );
    expect(
      t.matches(
        dayFor(hijri: const HijriDate(year: 1447, month: 9, day: 22)),
      ),
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

  test('weekday matches rolled IslamicDay weekday', () {
    final t = const ReflectionTrigger(type: 'weekday', weekday: 5);
    expect(
      t.matches(
        dayFor(
          hijri: const HijriDate(year: 1448, month: 2, day: 27),
          weekday: DateTime.friday,
        ),
      ),
      isTrue,
    );
  });

  test('time_of_day matches IslamicDay period', () {
    final t = const ReflectionTrigger(
      type: 'time_of_day',
      period: 'evening',
    );
    expect(
      t.matches(
        dayFor(
          hijri: hijri,
          period: TimeOfDayPeriod.evening,
        ),
      ),
      isTrue,
    );
    expect(t.matches(dayFor(hijri: hijri)), isFalse);
  });
}
