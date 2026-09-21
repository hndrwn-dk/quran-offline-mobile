import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:quran_offline/features/dua/widgets/explore_hub_section_card.dart';
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

Future<void> _pumpHub(
  WidgetTester tester, {
  required bool aiEnabled,
}) async {
  SharedPreferences.setMockInitialValues({
    'language': 'id',
    'appLanguage': 'id',
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: _hubOverrides(aiEnabled: aiEnabled),
      child: const MaterialApp(home: DuaScreen()),
    ),
  );
  await tester.pump();
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

  test('flag-on Jelajahi no longer hosts the doa resolver', () {
    final source = File('lib/features/dua/dua_screen.dart').readAsStringSync();
    expect(source.contains('DoaNeedResolver'), isFalse);
    expect(source.contains('previewDoaNeed'), isFalse);
    expect(source.contains('doa_need_header_'), isFalse);
  });

  testWidgets('flag off hub keeps catalog search and hides doa-need entry', (
    tester,
  ) async {
    await _pumpHub(tester, aiEnabled: false);

    expect(find.byType(ExploreHubSearchBar), findsOneWidget);
    expect(
      find.text(AppLocalizations.getExploreSearchHint('id')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('doa_need_entry')), findsNothing);
    expect(
      find.text(AppLocalizations.getDoaNeedTitle('id')),
      findsNothing,
    );

    final cards = tester
        .widgetList<ExploreHubSectionCard>(find.byType(ExploreHubSectionCard))
        .toList();
    expect(cards.map((c) => c.sectionKey).toList(), [
      'prophet',
      'science',
      'asma',
      'life_theme',
    ]);
  });

  testWidgets('flag on hub is browse-only with four cards and no search', (
    tester,
  ) async {
    await _pumpHub(tester, aiEnabled: true);

    expect(find.byType(ExploreHubSearchBar), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const Key('doa_need_entry')), findsNothing);
    expect(
      find.text(AppLocalizations.getDoaNeedTitle('id')),
      findsNothing,
    );
    expect(
      find.text(AppLocalizations.getSubtitleText('dua_subtitle', 'id')),
      findsOneWidget,
    );

    final cards = tester
        .widgetList<ExploreHubSectionCard>(find.byType(ExploreHubSectionCard))
        .toList();
    expect(cards.map((c) => c.sectionKey).toList(), [
      'prophet',
      'science',
      'asma',
      'life_theme',
    ]);
    expect(cards.map((c) => c.title).toList(), [
      AppLocalizations.getDuaCategoryLabel('prophet', 'id'),
      AppLocalizations.getDuaCategoryLabel('science', 'id'),
      AppLocalizations.getDuaCategoryLabel('asma', 'id'),
      AppLocalizations.getDuaCategoryLabel('life_theme', 'id'),
    ]);
    expect(tester.takeException(), isNull);
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
