import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:quran_offline/core/models/asma_entry.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/dua/open_explore_favorite.dart';
import 'package:quran_offline/features/dua/widgets/arabic_snippet.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocalizedText _text(String value) {
  return LocalizedText(id: value, en: value, zh: value, ja: value);
}

DuaEntry _dua(String id, String title) {
  return DuaEntry(
    id: id,
    category: 'prophet',
    prophet: 'zakaria',
    sort: 1,
    title: _text(title),
    summary: _text('ringkas'),
    ayahRefs: const [DuaAyahRef(surah: 21, from: 89, to: 89)],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<ExploreFavorite> favorites,
  required List<DuaEntry> duas,
}) async {
  SharedPreferences.setMockInitialValues({
    'appLanguage': 'id',
    'language': 'id',
    'explore_favorites_v1': encodeExploreFavorites(favorites),
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        duaCatalogProvider.overrideWith(
          (ref) async => DuaCatalog(version: 1, entries: duas),
        ),
        scienceCatalogProvider.overrideWith(
          (ref) async => const ScienceCatalog(version: 1, entries: []),
        ),
        asmaCatalogProvider.overrideWith(
          (ref) async => const AsmaCatalog(version: 1, entries: []),
        ),
        themeCatalogProvider.overrideWith(
          (ref) async => const ThemeCatalog(version: 1, entries: []),
        ),
        arabicSnippetLookupProvider.overrideWith(
          (ref) => (surah, ayah) async => 'snippet',
        ),
      ],
      child: const MaterialApp(home: ExploreFavoritesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty favorites show the invitation', (tester) async {
    await _pump(tester, favorites: const [], duas: const []);

    expect(
      find.text(AppLocalizations.getExploreFavoritesEmptyTitle('id')),
      findsOneWidget,
    );
    expect(
      find.text(AppLocalizations.getExploreFavoritesEmptyCta('id')),
      findsOneWidget,
    );
  });

  testWidgets('chips stay hidden when only one kind is saved', (tester) async {
    await _pump(
      tester,
      favorites: const [
        ExploreFavorite(
          kind: ExploreFavoriteKind.dua,
          id: 'satu',
          markedAtMillis: 2,
        ),
      ],
      duas: [_dua('satu', 'Satu doa')],
    );

    expect(find.text('Satu doa'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('undo puts a removed favorite back in its place', (tester) async {
    await _pump(
      tester,
      favorites: const [
        ExploreFavorite(
          kind: ExploreFavoriteKind.dua,
          id: 'baru',
          markedAtMillis: 20,
        ),
        ExploreFavorite(
          kind: ExploreFavoriteKind.dua,
          id: 'lama',
          markedAtMillis: 10,
        ),
      ],
      duas: [_dua('baru', 'Doa baru'), _dua('lama', 'Doa lama')],
    );

    expect(
      tester.getTopLeft(find.text('Doa baru')).dy,
      lessThan(tester.getTopLeft(find.text('Doa lama')).dy),
    );

    await tester.tap(find.byIcon(Icons.favorite).first);
    await tester.pumpAndSettle();
    expect(find.text('Doa baru'), findsNothing);

    await tester.tap(find.text(AppLocalizations.getExploreFavoritesUndo('id')));
    await tester.pumpAndSettle();

    expect(find.text('Doa baru'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Doa baru')).dy,
      lessThan(tester.getTopLeft(find.text('Doa lama')).dy),
    );
  });
}
