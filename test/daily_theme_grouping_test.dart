import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';

void main() {
  test('dailyGroupedByTheme returns eight themes in order', () {
    const catalog = DuaCatalog(
      version: 5,
      entries: [
        DuaEntry(
          id: 'a',
          category: 'daily',
          theme: 'gratitude',
          sort: 20,
          title: LocalizedText(id: 'a', en: 'a', zh: 'a', ja: 'a'),
          summary: LocalizedText(id: 'a', en: 'a', zh: 'a', ja: 'a'),
          ayahRefs: [DuaAyahRef(surah: 1, from: 1, to: 1)],
        ),
        DuaEntry(
          id: 'b',
          category: 'daily',
          theme: 'forgiveness',
          sort: 10,
          title: LocalizedText(id: 'b', en: 'b', zh: 'b', ja: 'b'),
          summary: LocalizedText(id: 'b', en: 'b', zh: 'b', ja: 'b'),
          ayahRefs: [DuaAyahRef(surah: 1, from: 2, to: 2)],
        ),
      ],
    );

    final grouped = catalog.dailyGroupedByTheme();
    expect(grouped.keys.toList(), ['forgiveness', 'gratitude']);
    expect(grouped['forgiveness']!.single.id, 'b');
  });
}
