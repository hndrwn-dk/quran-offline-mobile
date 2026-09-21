import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/doa_need_resolver.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/search/widgets/tanya_search_results.dart';

IndexHit _indexHit({
  required String id,
  required String type,
  double score = 1.0,
}) {
  return IndexHit(
    docId: id,
    type: type,
    lang: 'id',
    refKey: id,
    surah: 2,
    ayahFrom: 1,
    ayahTo: 1,
    score: score,
  );
}

AiSearchHit _aiHit(String type, String id) {
  return AiSearchHit(
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
  return DoaNeedItem(
    tier: tier,
    hit: _indexHit(id: id, type: type),
    score: 0.9,
  );
}

void main() {
  test('Cari Doa groups come from resolver and omit related-ayah tier', () {
    final keyword = AiSearchResults(
      groups: [
        AiSearchTypeGroup(type: 'ayah', hits: [_aiHit('ayah', 'ayah:keyword')]),
        AiSearchTypeGroup(type: 'dua', hits: [_aiHit('dua', 'dua:keyword')]),
        AiSearchTypeGroup(
          type: 'quran_dua',
          hits: [_aiHit('quran_dua', 'qd:keyword')],
        ),
      ],
    );
    final need = DoaNeedResult(
      tier1: [_item(DoaNeedTier.duaCatalog, 'dua:resolver', 'dua')],
      tier2: [_item(DoaNeedTier.quranDua, 'qd:resolver', 'quran_dua')],
      tier3: [_item(DoaNeedTier.relatedAyah, 'ayah:related', 'ayah')],
      tier3b: [_item(DoaNeedTier.asma, 'asma:17', 'asma')],
    );

    final merged = applyDoaNeedToCariResults(keyword, need);
    expect(merged.groups.map((g) => g.type).toList(), [
      'ayah',
      'dua',
      'quran_dua',
    ]);
    expect(merged.groups.first.hits.map((h) => h.docId), ['ayah:keyword']);
    expect(
      merged.groups.firstWhere((g) => g.type == 'dua').hits.map((h) => h.docId),
      ['dua:resolver'],
    );
    expect(
      merged.groups
          .firstWhere((g) => g.type == 'quran_dua')
          .hits
          .map((h) => h.docId),
      ['qd:resolver'],
    );
    expect(
      merged.groups.expand((g) => g.hits).map((h) => h.docId),
      isNot(contains('ayah:related')),
    );
    expect(
      merged.groups.expand((g) => g.hits).map((h) => h.docId),
      isNot(contains('asma:17')),
    );
  });

  testWidgets('Cari Doa headers use type labels, never the related-ayah tier', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TanyaSearchResults(
            groups: [
              AiSearchTypeGroup(
                type: 'ayah',
                hits: [_aiHit('ayah', 'ayah-1')],
              ),
              AiSearchTypeGroup(
                type: 'dua',
                hits: [_aiHit('dua', 'dua-1')],
              ),
              AiSearchTypeGroup(
                type: 'quran_dua',
                hits: [_aiHit('quran_dua', 'qd-1')],
              ),
            ],
            lang: 'id',
            translationCount: 0,
            cardBuilder: (hit, lang) => Text(hit.docId),
          ),
        ),
      ),
    );

    expect(find.text(AppLocalizations.getAiSearchTypeLabel('dua', 'id')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getAiSearchTypeLabel('quran_dua', 'id')),
      findsOneWidget,
    );
    expect(find.text(AppLocalizations.getAiSearchTypeLabel('ayah', 'id')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getDoaNeedTier3Header('id')),
      findsNothing,
    );
    expect(find.byKey(const Key('doa_need_header_tier3')), findsNothing);
  });
}
