import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/home/home_screen.dart';
import 'package:quran_offline/features/search/ai_search_query_kind.dart';
import 'package:quran_offline/features/search/search_screen.dart';
import 'package:quran_offline/features/search/widgets/ai_result_card.dart';
import 'package:quran_offline/features/search/widgets/search_result_list.dart';
import 'package:quran_offline/features/search/widgets/tanya_search_results.dart';
import 'package:shared_preferences/shared_preferences.dart';

AiSearchHit _hit(String type, double score, String id) {
  return AiSearchHit(
    docId: id,
    type: type,
    lang: 'en',
    refKey: id,
    surah: 2,
    ayahFrom: 1,
    ayahTo: 1,
    score: score,
  );
}

AiSearchTypeGroup _group(String type, int n, {double score = 1.0}) {
  return AiSearchTypeGroup(
    type: type,
    hits: [for (var i = 0; i < n; i++) _hit(type, score - i * 0.01, '$type-$i')],
  );
}

Widget _card(AiSearchHit hit, String lang) {
  return AiResultCard(
    typeLabel: hit.type,
    title: hit.docId,
    sourceRef: hit.refKey,
    showKurasiBadge: false,
  );
}

List<Override> _searchOverrides({
  required bool aiEnabled,
  required List<SearchResult> classic,
  required List<AiSearchTypeGroup> tanya,
  String query = 'sabar',
}) {
  return [
    aiSearchEnabledProvider.overrideWith((ref) => aiEnabled),
    tanyaCardBuilderProvider.overrideWith((ref) => _card),
    searchQueryProvider.overrideWith((ref) => query),
    enhancedSearchResultsProvider.overrideWith((ref) async => classic),
    aiSearchResultsProvider.overrideWith(
      (ref) async => AiSearchResults(groups: tanya),
    ),
  ];
}

SearchResult _classicTranslation() {
  return SearchResult(
    type: 'verse',
    title: 'classic translation hit',
    source: const SurahSource(2, targetAyahNo: 153),
    verseMatchKind: SearchVerseMatchKind.translation,
  );
}

SearchResult _classicRef() {
  return SearchResult(
    type: 'verse',
    title: 'QS 2:255',
    source: const SurahSource(2, targetAyahNo: 255),
    verseMatchKind: SearchVerseMatchKind.reference,
  );
}

SearchResult _classicSurah() {
  return SearchResult(
    type: 'surah',
    title: 'Al-Fatihah',
    source: const SurahSource(1),
  );
}

SearchResult _classicJuz() {
  return SearchResult(
    type: 'juz',
    title: 'Juz 30',
    source: const JuzSource(30),
  );
}

SearchResult _classicArabic() {
  return SearchResult(
    type: 'verse',
    title: 'arabic hit',
    subtitle: 'QS 1:1',
    source: const SurahSource(1, targetAyahNo: 1),
    verseMatchKind: SearchVerseMatchKind.arabic,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Temukan strings exist in all four languages', () {
    expect(AppLocalizations.getAiSearchHeading('id'), "Temukan di Al-Qur'an");
    expect(
      AppLocalizations.getAiSearchPlaceholder('id'),
      'Cari sabar, rezeki, atau 2:255',
    );
    expect(AppLocalizations.getNavMenuText('search', 'id'), 'Cari');
    expect(AppLocalizations.getAiSearchEmpty('id'), 'Belum ditemukan');
    expect(AppLocalizations.getAiSearchSeeAll('id'), 'Lihat semua');
    expect(AppLocalizations.getAiSearchTryLabel('id'), 'Coba:');
    expect(
      AppLocalizations.getAiSearchLandingHint('id'),
      'Bisa juga ketik 2:255, juz 30, halaman 5, atau teks Arab.',
    );
    expect(AppLocalizations.getAiSearchDirectGroup('id'), 'Langsung ke');
    expect(AppLocalizations.getAiSearchArabicGroup('id'), 'Teks Arab');
    expect(
      AppLocalizations.getAiSearchSeeTranslations('id'),
      'Lihat hasil terjemahan',
    );
    for (final lang in ['id', 'en', 'zh', 'ja']) {
      expect(AppLocalizations.getAiSearchHeading(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchPlaceholder(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchTryLabel(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchLandingHint(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchDirectGroup(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchArabicGroup(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchSeeTranslations(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchExampleQueries(lang), hasLength(4));
      expect(AppLocalizations.getAiSearchEmpty(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchSeeAll(lang), isNotEmpty);
      expect(
        AppLocalizations.getAiSearchTranslationJump(lang, 7),
        contains('7'),
      );
      expect(AppLocalizations.getAiSearchHeading(lang).toLowerCase(), isNot(contains('tanya')));
      expect(
        AppLocalizations.getAiSearchPlaceholder(lang).toLowerCase(),
        isNot(contains('tanya')),
      );
    }
  });

  test('detectAiSearchQueryKind routes reference, arabic, and grouped', () {
    expect(
      detectAiSearchQueryKind('2:255', [_classicRef()]),
      AiSearchQueryKind.direct,
    );
    expect(
      detectAiSearchQueryKind('juz 30', [_classicJuz()]),
      AiSearchQueryKind.direct,
    );
    expect(
      detectAiSearchQueryKind('Al-Fatihah', [_classicSurah()]),
      AiSearchQueryKind.direct,
    );
    expect(
      detectAiSearchQueryKind(
        AppLocalizations.getSearchSampleQuery('arabic', 'en'),
        [_classicArabic()],
      ),
      AiSearchQueryKind.arabic,
    );
    expect(
      detectAiSearchQueryKind('sabar', [_classicTranslation()]),
      AiSearchQueryKind.grouped,
    );
  });

  testWidgets('caps at 3 cards until Lihat semua expands the group', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: [_group('ayah', 5)],
            lang: 'id',
            translationCount: 0,
            cardBuilder: _card,
          ),
        ),
      ),
    );

    expect(find.byType(AiResultCard), findsNWidgets(3));
    expect(find.byKey(const Key('tanya_see_all_ayah')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tanya_see_all_ayah')));
    await tester.pump();
    expect(find.byType(AiResultCard), findsNWidgets(5));
  });

  testWidgets('hides empty groups and keeps ayah before tafsir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: [
              const AiSearchTypeGroup(type: 'dua', hits: []),
              _group('tafsir', 1, score: 0.9),
              _group('ayah', 1, score: 0.1),
            ],
            lang: 'id',
            translationCount: 0,
            cardBuilder: _card,
          ),
        ),
      ),
    );

    final ayah = tester.getTopLeft(find.byKey(const Key('ai_search_group_ayah')));
    final tafsir = tester.getTopLeft(find.byKey(const Key('ai_search_group_tafsir')));
    expect(ayah.dy, lessThan(tafsir.dy));
    expect(find.byKey(const Key('ai_search_group_dua')), findsNothing);
  });

  testWidgets('remaining groups sort by best score then listed tie-break', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: [
              _group('science', 1, score: 0.5),
              _group('dua', 1, score: 0.8),
              _group('asma', 1, score: 0.8),
              _group('theme', 1, score: 0.4),
              _group('quran_dua', 1, score: 0.8),
              _group('surah_info', 1, score: 0.9),
            ],
            lang: 'id',
            translationCount: 0,
            cardBuilder: _card,
          ),
        ),
      ),
    );

    final order = [
      'surah_info',
      'dua',
      'quran_dua',
      'asma',
      'science',
      'theme',
    ];
    for (var i = 0; i < order.length - 1; i++) {
      final top = tester.getTopLeft(find.byKey(Key('ai_search_group_${order[i]}')));
      final next = tester.getTopLeft(
        find.byKey(Key('ai_search_group_${order[i + 1]}')),
      );
      expect(top.dy, lessThan(next.dy), reason: '${order[i]} before ${order[i + 1]}');
    }
  });

  testWidgets('translation jump row opens the translation list screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: [_classicTranslation()],
          tanya: [_group('ayah', 1)],
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('tanya_translation_jump')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getAiSearchTranslationJump('en', 1)),
      findsOneWidget,
    );
    expect(
      find.text('classic translation hit', findRichText: true),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('tanya_translation_jump')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('translation_results_screen')), findsOneWidget);
    expect(find.byType(SearchResultList), findsOneWidget);
    expect(
      find.text('classic translation hit', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('empty state shows Belum ditemukan and translation button', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: const [],
            lang: 'id',
            translationCount: 4,
            onJumpToTranslation: () => opened = true,
            cardBuilder: _card,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('tanya_empty')), findsOneWidget);
    expect(find.text(AppLocalizations.getAiSearchEmpty('id')), findsOneWidget);
    expect(find.byKey(const Key('tanya_translation_jump')), findsNothing);
    expect(find.byKey(const Key('tanya_see_translations')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getAiSearchSeeTranslations('id')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('tanya_see_translations')));
    expect(opened, isTrue);
  });

  testWidgets('empty state has no button when classic search is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: [],
            lang: 'id',
            translationCount: 0,
            cardBuilder: _card,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('tanya_empty')), findsOneWidget);
    expect(find.byKey(const Key('tanya_see_translations')), findsNothing);
    expect(find.byKey(const Key('tanya_translation_jump')), findsNothing);
  });

  testWidgets('flag on hides filter chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: [_classicTranslation()],
          tanya: [_group('ayah', 1)],
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('search_filter_all')), findsNothing);
    expect(find.byKey(const Key('search_filter_surah')), findsNothing);
    expect(find.byKey(const Key('search_filter_terjemahan')), findsNothing);
    expect(find.byKey(const Key('ai_search_group_ayah')), findsOneWidget);
  });

  testWidgets('flag off keeps Semua chip and classic results', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: false,
          classic: [_classicTranslation()],
          tanya: [_group('ayah', 1)],
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(AppLocalizations.getSettingsText('filter_all', 'en')), findsOneWidget);
    expect(
      find.text('classic translation hit', findRichText: true),
      findsOneWidget,
    );
    expect(find.byKey(const Key('tanya_empty')), findsNothing);
    expect(find.byKey(const Key('tanya_translation_jump')), findsNothing);
    expect(find.byKey(const Key('ai_search_group_ayah')), findsNothing);
  });

  testWidgets('flag on uses Temukan header, placeholder, Cari nav, no subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._searchOverrides(
            aiEnabled: true,
            classic: const [],
            tanya: const [],
            query: '',
          ),
          currentTabProvider.overrideWith((ref) => AppTab.search),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(AppLocalizations.getAiSearchHeading('en')),
      ),
      findsWidgets,
    );
    expect(
      find.text(AppLocalizations.getSubtitleText('search_subtitle', 'en')),
      findsNothing,
    );
    expect(
      find.text(AppLocalizations.getAiSearchPlaceholder('en')),
      findsOneWidget,
    );
    final navOn = tester.widget<NavigationDestination>(
      find.byKey(const Key('nav_search')),
    );
    expect(navOn.label, AppLocalizations.getNavMenuText('search', 'en'));
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(AppLocalizations.getMenuText('search', 'en')),
      ),
      findsNothing,
    );
    expect(
      find.text(AppLocalizations.getSearchText('search_placeholder', 'en')),
      findsNothing,
    );
  });

  testWidgets('flag off keeps current header, placeholder, and nav label', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._searchOverrides(
            aiEnabled: false,
            classic: const [],
            tanya: const [],
            query: '',
          ),
          currentTabProvider.overrideWith((ref) => AppTab.search),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(AppLocalizations.getMenuText('search', 'en')), findsWidgets);
    expect(
      find.text(AppLocalizations.getSubtitleText('search_subtitle', 'en')),
      findsOneWidget,
    );
    expect(
      find.text(AppLocalizations.getSearchText('search_placeholder', 'en')),
      findsOneWidget,
    );
    final navOff = tester.widget<NavigationDestination>(
      find.byKey(const Key('nav_search')),
    );
    expect(navOff.label, AppLocalizations.getNavMenuText('search', 'en'));
    expect(find.byKey(const Key('tanya_landing_card')), findsNothing);
  });

  testWidgets('landing is try chips in one row plus hint, no cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: const [],
          tanya: const [],
          query: '',
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('tanya_landing_card')), findsNothing);
    expect(find.byKey(const Key('tanya_specific_heading')), findsNothing);
    expect(find.byKey(const Key('tanya_try_label')), findsOneWidget);
    expect(find.byKey(const Key('tanya_landing_hint')), findsOneWidget);
    expect(find.byKey(const Key('tanya_example_row')), findsOneWidget);
    expect(find.byKey(const Key('tanya_example_3')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getSearchText('search_by_label', 'en')),
      findsNothing,
    );
    expect(
      find.text(AppLocalizations.getMenuText('surah', 'en')),
      findsNothing,
    );
    final y0 = tester.getTopLeft(find.byKey(const Key('tanya_example_0'))).dy;
    final y3 = tester.getTopLeft(find.byKey(const Key('tanya_example_3'))).dy;
    expect(y0, y3);
  });

  testWidgets('example chip fills the query and runs it', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: const [],
          tanya: const [],
          query: '',
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final example = AppLocalizations.getAiSearchExampleQueries('en').first;
    await tester.tap(find.byKey(const Key('tanya_example_0')));
    await tester.pump();

    final field = tester.widget<TextField>(find.byKey(const Key('search_field')));
    expect(field.controller?.text, example);
  });

  testWidgets('reference query shows Langsung ke, not grouped hits', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: [_classicRef(), _classicTranslation()],
          tanya: [_group('ayah', 1)],
          query: '2:255',
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ai_search_group_direct')), findsOneWidget);
    expect(find.byKey(const Key('ai_search_group_ayah')), findsNothing);
    expect(find.byKey(const Key('search_filter_all')), findsNothing);
    expect(find.text('QS 2:255', findRichText: true), findsOneWidget);
  });

  testWidgets('juz query shows Langsung ke', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: [_classicJuz()],
          tanya: [_group('ayah', 1)],
          query: 'juz 30',
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ai_search_group_direct')), findsOneWidget);
    expect(find.text('Juz 30', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('ai_search_group_ayah')), findsNothing);
  });

  testWidgets('surah query shows Langsung ke', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: [_classicSurah()],
          tanya: [_group('ayah', 1)],
          query: 'Al-Fatihah',
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ai_search_group_direct')), findsOneWidget);
    expect(find.byType(SearchResultTile), findsOneWidget);
    expect(find.byKey(const Key('ai_search_group_ayah')), findsNothing);
  });

  testWidgets('arabic-script query shows Teks Arab group', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: [_classicArabic()],
          tanya: [_group('ayah', 1)],
          query: AppLocalizations.getSearchSampleQuery('arabic', 'en'),
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ai_search_group_arabic')), findsOneWidget);
    expect(find.byKey(const Key('ai_search_group_ayah')), findsNothing);
    expect(find.text('arabic hit', findRichText: true), findsOneWidget);
  });

  testWidgets('keyword query shows grouped Ayat then Tafsir', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _searchOverrides(
          aiEnabled: true,
          classic: [_classicTranslation()],
          tanya: [
            _group('tafsir', 1, score: 0.9),
            _group('ayah', 1, score: 0.1),
          ],
        ),
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('search_filter_all')), findsNothing);
    final ayah = tester.getTopLeft(find.byKey(const Key('ai_search_group_ayah')));
    final tafsir = tester.getTopLeft(
      find.byKey(const Key('ai_search_group_tafsir')),
    );
    expect(ayah.dy, lessThan(tafsir.dy));
  });
}
