import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/features/search/tanya_result_layout.dart';

AiSearchHit _hit(String type, double score, String id) {
  return AiSearchHit(
    docId: id,
    type: type,
    lang: 'id',
    refKey: id,
    score: score,
  );
}

AiSearchTypeGroup _group(String type, List<double> scores) {
  return AiSearchTypeGroup(
    type: type,
    hits: [
      for (var i = 0; i < scores.length; i++)
        _hit(type, scores[i], '$type-$i'),
    ],
  );
}

void main() {
  test('ayah then tafsir stay first even when other scores are higher', () {
    final laid = layoutTanyaGroups([
      _group('theme', [0.99]),
      _group('tafsir', [0.2]),
      _group('ayah', [0.3]),
      _group('dua', [0.95]),
    ]);
    expect(laid.map((g) => g.type).toList(), ['ayah', 'tafsir', 'theme', 'dua']);
  });

  test('remaining groups sort by best score then listed tie-break', () {
    final laid = layoutTanyaGroups([
      _group('science', [0.5]),
      _group('dua', [0.8]),
      _group('asma', [0.8]),
      _group('theme', [0.4]),
      _group('quran_dua', [0.8]),
      _group('surah_info', [0.9]),
    ]);
    expect(laid.map((g) => g.type).toList(), [
      'surah_info',
      'dua',
      'quran_dua',
      'asma',
      'science',
      'theme',
    ]);
  });

  test('empty groups are hidden', () {
    final laid = layoutTanyaGroups([
      const AiSearchTypeGroup(type: 'ayah', hits: []),
      _group('tafsir', [1.0]),
      const AiSearchTypeGroup(type: 'dua', hits: []),
    ]);
    expect(laid.map((g) => g.type).toList(), ['tafsir']);
  });

  test('preview cap is 3 and expand uses kMaxResultsPerType', () {
    final group = _group('ayah', [1, 0.9, 0.8, 0.7, 0.6]);
    expect(tanyaVisibleHits(group, expanded: false), hasLength(kTanyaPreviewPerGroup));
    expect(tanyaVisibleHits(group, expanded: true), hasLength(5));
    expect(tanyaNeedsSeeAll(group), isTrue);
    expect(tanyaNeedsSeeAll(_group('ayah', [1, 0.9, 0.8])), isFalse);
  });
}
