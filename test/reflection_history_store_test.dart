import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/providers/reflection_history_store.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';

void main() {
  test('write then read returns same ymd slot id', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ReflectionHistoryStore();
    await store.write(
      const ReflectionSlotCache(
        ymd: '2026-08-25',
        slot: ReflectionSlot.morning,
        id: 'pagi_syukur',
      ),
    );
    final got = await store.read();
    expect(got?.ymd, '2026-08-25');
    expect(got?.slot, ReflectionSlot.morning);
    expect(got?.id, 'pagi_syukur');
  });

  test('read returns null for empty prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ReflectionHistoryStore();
    expect(await store.read(), isNull);
  });

  test('malformed JSON returns null without throwing', () async {
    SharedPreferences.setMockInitialValues({
      ReflectionHistoryStore.prefsKey: '{not-json',
    });
    final store = ReflectionHistoryStore();
    expect(await store.read(), isNull);
  });

  test('unknown slot name returns null without throwing', () async {
    SharedPreferences.setMockInitialValues({
      ReflectionHistoryStore.prefsKey:
          '{"ymd":"2026-08-25","slot":"night","id":"x"}',
    });
    final store = ReflectionHistoryStore();
    expect(await store.read(), isNull);
  });
}
