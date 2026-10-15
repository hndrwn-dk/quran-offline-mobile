import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:quran_offline/core/models/asma_entry.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';

LocalizedText _text(String value) {
  return LocalizedText(id: value, en: value, zh: value, ja: value);
}

void main() {
  test('marking a favorite puts it first and toggles off', () {
    final first = toggleExploreFavorite(
      const [],
      ExploreFavoriteKind.dua,
      'morning',
      10,
    );
    final both = toggleExploreFavorite(
      first,
      ExploreFavoriteKind.science,
      'cosmos',
      20,
    );

    expect(both.map((item) => item.key).toList(), ['science:cosmos', 'dua:morning']);

    final removed = toggleExploreFavorite(
      both,
      ExploreFavoriteKind.science,
      'cosmos',
      30,
    );
    expect(removed.map((item) => item.key).toList(), ['dua:morning']);
  });

  test('saving again after removal puts it first', () {
    final stored = toggleExploreFavorite(
      toggleExploreFavorite(const [], ExploreFavoriteKind.asma, '1', 10),
      ExploreFavoriteKind.theme,
      'hope',
      20,
    );
    final removed = toggleExploreFavorite(
      stored,
      ExploreFavoriteKind.asma,
      '1',
      25,
    );
    final again = toggleExploreFavorite(
      removed,
      ExploreFavoriteKind.asma,
      '1',
      30,
    );

    expect(again.first.key, 'asma:1');
    expect(again.first.markedAtMillis, 30);
    expect(again.last.key, 'theme:hope');
  });

  test('same id in another kind stays separate', () {
    final stored = toggleExploreFavorite(
      toggleExploreFavorite(const [], ExploreFavoriteKind.dua, 'rahman', 10),
      ExploreFavoriteKind.asma,
      'rahman',
      20,
    );

    expect(stored, hasLength(2));
    expect(
      toggleExploreFavorite(stored, ExploreFavoriteKind.dua, 'rahman', 30),
      hasLength(1),
    );
  });

  test('round trip keeps newest first and drops unknown kinds', () {
    final stored = [
      const ExploreFavorite(
        kind: ExploreFavoriteKind.theme,
        id: 'patience',
        markedAtMillis: 5,
      ),
      const ExploreFavorite(
        kind: ExploreFavoriteKind.dua,
        id: 'travel',
        markedAtMillis: 9,
      ),
    ];

    final encoded = jsonDecode(encodeExploreFavorites(stored)) as List<dynamic>;
    encoded.add({'kind': 'nope', 'id': 'x', 'markedAtMillis': 1});
    final decoded = decodeExploreFavorites(jsonEncode(encoded));

    expect(decoded.map((item) => item.key).toList(), [
      'dua:travel',
      'theme:patience',
    ]);
  });

  test('resolve skips a favorite whose catalog entry is gone', () {
    final views = resolveExploreFavorites(
      favorites: const [
        ExploreFavorite(
          kind: ExploreFavoriteKind.science,
          id: 'missing',
          markedAtMillis: 3,
        ),
        ExploreFavorite(
          kind: ExploreFavoriteKind.dua,
          id: 'rain',
          markedAtMillis: 2,
        ),
      ],
      lang: 'id',
      duas: [
        DuaEntry(
          id: 'rain',
          category: 'daily',
          sort: 1,
          title: _text('Doa hujan'),
          summary: _text('ringkas'),
          ayahRefs: const [DuaAyahRef(surah: 2, from: 186, to: 186)],
        ),
      ],
      science: const <ScienceEntry>[],
      asma: const <AsmaEntry>[],
      themes: const <ThemeEntry>[],
    );

    expect(views, hasLength(1));
    expect(views.single.title, 'Doa hujan');
    expect(views.single.favorite.kind, ExploreFavoriteKind.dua);
  });

  test('restore puts a removed favorite back in its original place', () {
    const newest = ExploreFavorite(
      kind: ExploreFavoriteKind.dua,
      id: 'a',
      markedAtMillis: 30,
    );
    const middle = ExploreFavorite(
      kind: ExploreFavoriteKind.science,
      id: 'b',
      markedAtMillis: 20,
    );
    const oldest = ExploreFavorite(
      kind: ExploreFavoriteKind.asma,
      id: 'c',
      markedAtMillis: 10,
    );
    final removed = toggleExploreFavorite(
      const [newest, middle, oldest],
      ExploreFavoriteKind.science,
      'b',
      99,
    );

    expect(removed.map((item) => item.key).toList(), ['dua:a', 'asma:c']);

    final restored = restoreExploreFavorite(removed, middle);
    expect(restored.map((item) => item.key).toList(), [
      'dua:a',
      'science:b',
      'asma:c',
    ]);
    expect(restored[1].markedAtMillis, 20);
  });
}
