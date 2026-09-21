import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/doa_need_resolver.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/quran_dua_ayat_catalog_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/dua/dua_screen.dart';
import 'package:quran_offline/features/dua/widgets/explore_hub_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Override> _hubOverrides({required bool aiEnabled}) {
  return [
    aiSearchEnabledProvider.overrideWith((ref) => aiEnabled),
    duaCatalogProvider.overrideWith(
      (ref) async => const DuaCatalog(version: 1, entries: []),
    ),
    asmaCatalogProvider.overrideWith(
      (ref) async => const AsmaCatalog(version: 1, entries: []),
    ),
    scienceCatalogProvider.overrideWith(
      (ref) async => const ScienceCatalog(version: 1, entries: []),
    ),
    themeCatalogProvider.overrideWith(
      (ref) async => const ThemeCatalog(version: 1, entries: []),
    ),
    quranDuaAyatCatalogProvider.overrideWith(
      (ref) async => const QuranDuaAyatCatalog(version: 1, entries: []),
    ),
    searchIndexRepositoryProvider.overrideWith((ref) => _EmptyIndex()),
  ];
}

class _EmptyIndex extends SearchIndexRepository {
  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<IndexHit>> keywordSearch(
    String query, {
    Set<String>? types,
    String lang = 'id',
    int limit = 100,
  }) async {
    return const [];
  }
}

IndexHit _hit(String id, String type) {
  return IndexHit(
    docId: id,
    type: type,
    lang: 'id',
    refKey: id,
    surah: 2,
    ayahFrom: 1,
    ayahTo: 1,
    score: 1.0,
  );
}

DoaNeedItem _item(DoaNeedTier tier, String id, String type) {
  return DoaNeedItem(tier: tier, hit: _hit(id, type), score: 1.0);
}

Future<void> _enterQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('doa-need screen file is removed', () {
    expect(File('lib/features/dua/doa_need_screen.dart').existsSync(), isFalse);
    expect(
      File('lib/features/dua/dua_screen.dart').readAsStringSync().contains(
            'DoaNeedScreen',
          ),
      isFalse,
    );
  });

  testWidgets('flag off hub keeps catalog search and hides doa-need entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _hubOverrides(aiEnabled: false),
        child: const MaterialApp(home: DuaScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ExploreHubSearchBar), findsOneWidget);
    expect(
      find.text(AppLocalizations.getExploreSearchHint('en')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('doa_need_entry')), findsNothing);
    expect(find.byKey(const Key('doa_need_header_tier1')), findsNothing);
  });

  testWidgets('flag on hub keeps search on the same screen and has no doa card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _hubOverrides(aiEnabled: true),
        child: const MaterialApp(home: DuaScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ExploreHubSearchBar), findsOneWidget);
    expect(
      find.text(AppLocalizations.getExploreNeedSearchHint('en')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('doa_need_entry')), findsNothing);
  });

  testWidgets('flag on search shows doa-need tiers on the Jelajahi screen', (
    tester,
  ) async {
    final preview = DoaNeedResult(
      tier1: [_item(DoaNeedTier.duaCatalog, 'dua:one', 'dua')],
      tier2: [_item(DoaNeedTier.quranDua, 'qdua:two', 'quran_dua')],
      tier3: const [],
      tier3b: [_item(DoaNeedTier.asma, 'asma:17', 'asma')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _hubOverrides(aiEnabled: true),
        child: MaterialApp(home: DuaScreen(previewDoaNeed: preview)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await _enterQuery(tester, 'anak sakit');

    expect(find.byKey(const Key('doa_need_header_tier1')), findsOneWidget);
    expect(find.byKey(const Key('doa_need_header_tier2')), findsOneWidget);
    expect(find.byKey(const Key('doa_need_header_tier3b')), findsOneWidget);
    expect(find.byKey(const Key('doa_need_header_tier3')), findsNothing);
    expect(
      find.text(AppLocalizations.getDoaNeedTier3Header('en')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('flag on hides tier 3 when tier 1 has results', (tester) async {
    final preview = DoaNeedResult(
      tier1: [_item(DoaNeedTier.duaCatalog, 'dua:one', 'dua')],
      tier2: const [],
      tier3: [_item(DoaNeedTier.relatedAyah, 'ayah:2:1', 'ayah')],
      tier3b: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _hubOverrides(aiEnabled: true),
        child: MaterialApp(home: DuaScreen(previewDoaNeed: preview)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await _enterQuery(tester, 'sabar');

    expect(find.byKey(const Key('doa_need_header_tier1')), findsOneWidget);
    expect(find.byKey(const Key('doa_need_header_tier3')), findsNothing);
  });

  testWidgets('flag on shows tier 3 only when tiers 1 and 2 are empty', (
    tester,
  ) async {
    final preview = DoaNeedResult(
      tier1: const [],
      tier2: const [],
      tier3: [_item(DoaNeedTier.relatedAyah, 'ayah:2:1', 'ayah')],
      tier3b: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _hubOverrides(aiEnabled: true),
        child: MaterialApp(home: DuaScreen(previewDoaNeed: preview)),
      ),
    );
    await tester.pump();
    await tester.pump();
    await _enterQuery(tester, 'gelisah');

    expect(find.byKey(const Key('doa_need_header_tier3')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getDoaNeedTier3Header('en')),
      findsWidgets,
    );
  });

  test('new explore search dart files contain no Arabic literals', () {
    const arabic = r'[\u0600-\u06FF]';
    final files = [
      File('lib/features/dua/dua_screen.dart'),
      File('test/explore_doa_need_search_test.dart'),
    ];
    for (final file in files) {
      expect(
        RegExp(arabic).hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });
}
