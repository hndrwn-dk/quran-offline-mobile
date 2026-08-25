import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/providers/reflection_history_store.dart';

void main() {
  test('write then read today returns same ymd id', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ReflectionHistoryStore();
    await store.writeToday(ymd: '1448-02-27', id: 'jumat_kahf');
    final got = await store.readToday();
    expect(got?.ymd, '1448-02-27');
    expect(got?.id, 'jumat_kahf');
  });

  test('readToday returns null for empty prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ReflectionHistoryStore();
    expect(await store.readToday(), isNull);
  });

  test('malformed today JSON returns null without throwing', () async {
    SharedPreferences.setMockInitialValues({
      ReflectionHistoryStore.todayKey: '{not-json',
    });
    final store = ReflectionHistoryStore();
    expect(await store.readToday(), isNull);
  });

  test('readRecentIds trims to the current cap', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ReflectionHistoryStore();
    for (var i = 0; i < 20; i++) {
      await store.pushRecentId('id-$i');
    }
    final trimmed = await store.readRecentIds(cap: 10);
    expect(trimmed.length, 10);
    expect(trimmed.first, 'id-19');
    expect(trimmed.last, 'id-10');
  });
}
