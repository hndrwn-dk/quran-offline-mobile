import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';

const _text = LocalizedText(id: 't', en: 't', zh: 't', ja: 't');

ReflectionLensEntry entry({ReflectionTrigger? trigger}) {
  return ReflectionLensEntry(
    id: 'x',
    sort: 0,
    priority: 0,
    badgeKey: 'friday',
    title: _text,
    summary: _text,
    reflection: _text,
    ayahRefs: const [DuaAyahRef(surah: 1, from: 1, to: 1)],
    trigger: trigger,
  );
}

void main() {
  test('occasion badge shows only for hijri_day and hijri_month', () {
    expect(
      entry(
        trigger: const ReflectionTrigger(type: 'hijri_month', hijriMonth: 9),
      ).showsOccasionBadge,
      isTrue,
    );
    expect(
      entry(
        trigger: const ReflectionTrigger(
          type: 'hijri_day',
          hijriMonth: 1,
          hijriDay: 1,
        ),
      ).showsOccasionBadge,
      isTrue,
    );
    expect(
      entry(
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      ).showsOccasionBadge,
      isFalse,
    );
    expect(
      entry(
        trigger: const ReflectionTrigger(
          type: 'time_of_day',
          period: 'morning',
        ),
      ).showsOccasionBadge,
      isFalse,
    );
    expect(entry().showsOccasionBadge, isFalse);
  });
}
