import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _text = LocalizedText(id: 't', en: 't', zh: 't', ja: 't');

final _fridayCalendar = [
  ReflectionLensEntry(
    id: 'jumat_kahf',
    sort: 0,
    priority: 50,
    badgeKey: 'friday',
    title: _text,
    summary: _text,
    reflection: _text,
    ayahRefs: const [DuaAyahRef(surah: 1, from: 1, to: 1)],
    trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
  ),
];

ProviderContainer _container({
  required DateTime now,
  required List<ReflectionLensEntry> calendar,
  required List<ReflectionLensEntry> weekly,
}) {
  return ProviderContainer(
    overrides: [
      reflectionNowProvider.overrideWith((ref) => now),
      calendarLensesProvider.overrideWith(
        (ref) async => ReflectionCatalog(version: 1, entries: calendar),
      ),
      weeklyRotationProvider.overrideWith(
        (ref) async => ReflectionCatalog(version: 1, entries: weekly),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reflection pick provider loads catalogs and returns a pick', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pick = await container.read(reflectionPickProvider.future);
    expect(pick.entry.id, isNotEmpty);
    expect(pick.entry.title.id, isNotEmpty);
    expect(pick.entry.title.en, isNotEmpty);
    expect(pick.entry.title.zh, isNotEmpty);
    expect(pick.entry.title.ja, isNotEmpty);
    expect(pick.entry.ayahRefs, isNotEmpty);
  });

  test(
    'empty weekly with loaded calendar uses fallbacks on ordinary Tuesday midday',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 8, 25, 14);
      expect(now.weekday, DateTime.tuesday);
      final container = _container(
        now: now,
        calendar: _fridayCalendar,
        weekly: const [],
      );
      addTearDown(container.dispose);
      final pick = await container.read(reflectionPickProvider.future);
      expect(
        pick.entry.id,
        isIn(['fallback_fatihah', 'fallback_ikhlas', 'fallback_asr']),
      );
      expect(pick.source, ReflectionPickSource.weekly);
    },
  );

  test('empty weekly still keeps matching calendar entries', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 8, 21, 8);
    expect(now.weekday, DateTime.friday);
    final container = _container(
      now: now,
      calendar: _fridayCalendar,
      weekly: const [],
    );
    addTearDown(container.dispose);
    final pick = await container.read(reflectionPickProvider.future);
    expect(pick.entry.id, 'jumat_kahf');
    expect(pick.source, ReflectionPickSource.calendar);
  });
}
