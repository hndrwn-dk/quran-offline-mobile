import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
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
}) {
  return [
    aiSearchEnabledProvider.overrideWith((ref) => aiEnabled),
    tanyaCardBuilderProvider.overrideWith((ref) => _card),
    searchQueryProvider.overrideWith((ref) => 'sabar'),
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
    expect(AppLocalizations.getAiSearchEmpty('id'), 'Belum ditemukan');
    expect(AppLocalizations.getAiSearchSeeAll('id'), 'Lihat semua');
    for (final lang in ['id', 'en', 'zh', 'ja']) {
      expect(AppLocalizations.getAiSearchHeading(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchEmpty(lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchSeeAll(lang), isNotEmpty);
      expect(
        AppLocalizations.getAiSearchTranslationJump(lang, 7),
        contains('7'),
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
}
