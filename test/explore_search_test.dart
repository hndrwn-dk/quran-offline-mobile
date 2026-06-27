import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/features/dua/explore_search.dart';

void main() {
  test('searchExploreContent matches dua title case-insensitively', () {
    const catalog = DuaCatalog(version: 1, entries: []);
    expect(
      searchExploreContent(
        query: 'sabar',
        lang: 'id',
        duaCatalog: catalog,
      ),
      isEmpty,
    );
  });

  test('exploreLocalizedTextMatches searches all locale fields', () {
    const text = LocalizedText(
      id: 'Kesabaran',
      en: 'Patience',
      zh: '忍耐',
      ja: '忍耐',
    );
    expect(exploreLocalizedTextMatches(text, 'patience'), isTrue);
    expect(exploreLocalizedTextMatches(text, 'xyz'), isFalse);
    expect(exploreLocalizedTextMatches(text, 'kesabaran'), isTrue);
  });
}
