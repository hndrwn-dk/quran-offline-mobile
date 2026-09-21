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
import 'package:quran_offline/features/search/search_screen.dart';
import 'package:quran_offline/features/search/widgets/ai_result_card.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Tanya strings exist in all four languages', () {
    expect(AppLocalizations.getAiSearchHeading('id'), "Tanya Al-Qur'an");
    expect(AppLocalizations.getAiSearchNavLabel('id'), 'Tanya');
    expect(AppLocalizations.getAiSearchEmpty('id'), 'Belum ditemukan');
    expect(AppLocalizations.getAiSearchSeeAll('id'), 'Lihat semua');
    for (final lang in ['id', 'en', 'zh', 'ja']) {
      expect(AppLocalizations.getAiSearchHeading(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchNavLabel(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchScreenSubtitle(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchPlaceholder(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchLandingSubtitle(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchSpecificHeading(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchExampleQueries(lang), hasLength(4));
      expect(AppLocalizations.getAiSearchEmpty(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchSeeAll(lang), isNotEmpty);
      expect(
        AppLocalizations.getAiSearchTranslationJump(lang, 7),
        contains('7'),
      );
      expect(
        AppLocalizations.getSearchNoResultsForFilter(
          lang,
          'surah',
          tanyaEnabled: true,
        ),
        contains(AppLocalizations.getAiSearchHeading(lang)),
      );
      expect(
        AppLocalizations.getSearchNoResultsForFilter(
          lang,
          'surah',
          tanyaEnabled: false,
        ),
        isNot(contains(AppLocalizations.getAiSearchHeading(lang))),
      );
    }
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

  testWidgets('translation jump row does not render classic hits', (tester) async {
    var jumped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: [_group('ayah', 1)],
            lang: 'id',
            translationCount: 7,
            onJumpToTranslation: () => jumped = true,
            cardBuilder: _card,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('tanya_translation_jump')), findsOneWidget);
    expect(find.text(AppLocalizations.getAiSearchTranslationJump('id', 7)), findsOneWidget);
    expect(find.text('classic translation row'), findsNothing);
    await tester.tap(find.byKey(const Key('tanya_translation_jump')));
    expect(jumped, isTrue);
  });

  testWidgets('empty state shows Belum ditemukan and optional translation jump', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: [],
            lang: 'id',
            translationCount: 4,
            cardBuilder: _card,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('tanya_empty')), findsOneWidget);
    expect(find.text(AppLocalizations.getAiSearchEmpty('id')), findsOneWidget);
    expect(find.byKey(const Key('tanya_translation_jump')), findsOneWidget);
  });

  testWidgets('default all chip is Tanya Al-Qur\'an when flag on', (tester) async {
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

    expect(find.byKey(const Key('search_filter_all')), findsOneWidget);
    expect(find.text(AppLocalizations.getAiSearchHeading('en')), findsWidgets);
    expect(find.text(AppLocalizations.getSettingsText('filter_all', 'en')), findsNothing);
    expect(
      find.text('classic translation hit', findRichText: true),
      findsNothing,
    );
    expect(find.byKey(const Key('tanya_translation_jump')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tanya_translation_jump')));
    await tester.pump();
    expect(
      find.text('classic translation hit', findRichText: true),
      findsOneWidget,
    );
    expect(find.byKey(const Key('tanya_translation_jump')), findsNothing);
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

  testWidgets('flag on uses Tanya header, placeholder, and nav label', (
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
      find.text(AppLocalizations.getAiSearchScreenSubtitle('en')),
      findsOneWidget,
    );
    expect(
      find.text(AppLocalizations.getAiSearchPlaceholder('en')),
      findsOneWidget,
    );
    expect(find.text(AppLocalizations.getAiSearchNavLabel('en')), findsOneWidget);
    final navOn = tester.widget<NavigationDestination>(
      find.byKey(const Key('nav_search')),
    );
    expect(navOn.label, AppLocalizations.getAiSearchNavLabel('en'));
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
    expect(find.text(AppLocalizations.getAiSearchNavLabel('en')), findsNothing);
    expect(find.byKey(const Key('tanya_landing_card')), findsNothing);
  });

  testWidgets('landing puts Tanya card and example chips above specific search', (
    tester,
  ) async {
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

    final landing = tester.getTopLeft(find.byKey(const Key('tanya_landing_card')));
    final chip = tester.getTopLeft(find.byKey(const Key('tanya_example_0')));
    final specific = tester.getTopLeft(
      find.byKey(const Key('tanya_specific_heading')),
    );
    final surah = tester.getTopLeft(
      find.text(AppLocalizations.getMenuText('surah', 'en')),
    );
    expect(landing.dy, lessThan(chip.dy));
    expect(chip.dy, lessThan(specific.dy));
    expect(specific.dy, lessThan(surah.dy));
    expect(find.byKey(const Key('tanya_example_3')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getSearchText('search_by_label', 'en')),
      findsNothing,
    );
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

  testWidgets('empty-state button switches to the Tanya chip', (tester) async {
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

    await tester.tap(find.byKey(const Key('search_filter_surah')));
    await tester.pump();

    expect(find.byKey(const Key('search_show_all_filter')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getAiSearchHeading('en')),
      findsWidgets,
    );
    expect(
      find.text(AppLocalizations.getSearchText('search_show_all_filter', 'en')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('search_show_all_filter')));
    await tester.pump();
    expect(find.byKey(const Key('ai_search_group_ayah')), findsOneWidget);
  });
}
