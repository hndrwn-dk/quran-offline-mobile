import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:quran_offline/core/explore/favorite_display.dart';
import 'package:quran_offline/core/models/asma_entry.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';

LocalizedText _text(String value) {
  return LocalizedText(id: value, en: value, zh: value, ja: value);
}

void main() {
  final duas = [
    DuaEntry(
      id: 'zakaria',
      category: 'prophet',
      prophet: 'zakaria',
      sort: 1,
      title: _text('Mohon keturunan'),
      summary: _text('ringkas'),
      ayahRefs: const [
        DuaAyahRef(surah: 21, from: 89, to: 89),
        DuaAyahRef(surah: 3, from: 38, to: 38),
      ],
    ),
    DuaEntry(
      id: 'pagi',
      category: 'daily',
      theme: 'gratitude',
      sort: 2,
      title: _text('Doa pagi'),
      summary: _text('ringkas'),
      ayahRefs: const [DuaAyahRef(surah: 2, from: 186, to: 186)],
    ),
  ];
  final science = [
    ScienceEntry(
      id: 'sky',
      category: 'cosmos',
      sort: 1,
      title: _text('Langit'),
      summary: _text('ringkas'),
      scienceNote: _text('catatan'),
      ayahRefs: const [DuaAyahRef(surah: 51, from: 47, to: 47)],
    ),
  ];
  final asma = [
    AsmaEntry(
      id: 'rahman',
      number: 1,
      sort: 1,
      arabic: 'الرحمن',
      transliteration: 'Ar-Rahman',
      title: _text('Yang Maha Pengasih'),
      summary: _text('ringkas'),
      reflection: _text('renung'),
      ayahRefs: const [
        DuaAyahRef(surah: 1, from: 1, to: 1),
        DuaAyahRef(surah: 55, from: 1, to: 1),
      ],
    ),
  ];
  final themes = [
    ThemeEntry(
      id: 'sabar',
      category: 'patience',
      sort: 1,
      title: _text('Sabar'),
      summary: _text('ringkas'),
      reflection: _text('renung'),
      ayahRefs: const [DuaAyahRef(surah: 2, from: 153, to: 153)],
    ),
  ];

  FavoriteDisplay resolve(ExploreFavorite favorite) {
    final display = resolveFavoriteDisplay(
      favorite: favorite,
      lang: 'id',
      duas: duas,
      science: science,
      asma: asma,
      themes: themes,
    );
    expect(display, isNotNull);
    return display!;
  }

  test('prophet dua uses prophet category, name, and extra refs', () {
    final display = resolve(
      const ExploreFavorite(
        kind: ExploreFavoriteKind.dua,
        id: 'zakaria',
        markedAtMillis: 1,
      ),
    );
    expect(display.categoryLabel, 'Doa para nabi');
    expect(display.sourceLabel, 'Nabi Zakaria');
    expect(display.qsLabel, 'QS 21:89 +1');
    expect(display.accent, FavoriteAccent.green);
    expect(display.iconSection, 'prophet');
    expect(display.snippetSurah, 21);
    expect(display.snippetAyah, 89);
  });

  test('daily dua uses daily category and theme source', () {
    final display = resolve(
      const ExploreFavorite(
        kind: ExploreFavoriteKind.dua,
        id: 'pagi',
        markedAtMillis: 1,
      ),
    );
    expect(display.categoryLabel, 'Doa harian');
    expect(display.sourceLabel, 'Syukur');
    expect(display.qsLabel, 'QS 2:186');
    expect(display.accent, FavoriteAccent.green);
    expect(display.iconSection, 'prophet');
  });

  test('science uses science category and a single verse ref', () {
    final display = resolve(
      const ExploreFavorite(
        kind: ExploreFavoriteKind.science,
        id: 'sky',
        markedAtMillis: 1,
      ),
    );
    expect(display.categoryLabel, 'Sains');
    expect(display.sourceLabel, 'Alam semesta');
    expect(display.qsLabel, 'QS 51:47');
    expect(display.accent, FavoriteAccent.blue);
    expect(display.iconSection, 'science');
  });

  test('asma uses the catalog name and skips the verse ref', () {
    final display = resolve(
      const ExploreFavorite(
        kind: ExploreFavoriteKind.asma,
        id: 'rahman',
        markedAtMillis: 1,
      ),
    );
    expect(display.categoryLabel, 'Asmaul Husna');
    expect(display.sourceLabel, 'No. 1');
    expect(display.qsLabel, isNull);
    expect(display.catalogArabic, 'الرحمن');
    expect(display.accent, FavoriteAccent.sand);
    expect(display.iconSection, 'asma');
    expect(display.snippetSurah, isNull);
  });

  test('theme uses life-theme category and theme source', () {
    final display = resolve(
      const ExploreFavorite(
        kind: ExploreFavoriteKind.theme,
        id: 'sabar',
        markedAtMillis: 1,
      ),
    );
    expect(display.categoryLabel, 'Tema hidup');
    expect(display.sourceLabel, 'Sabar & ketenangan');
    expect(display.qsLabel, 'QS 2:153');
    expect(display.accent, FavoriteAccent.green);
    expect(display.iconSection, 'life_theme');
  });
}
