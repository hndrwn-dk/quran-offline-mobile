import 'package:quran_offline/core/ai_search/ai_search_config.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';

const int kTanyaPreviewPerGroup = 3;

const List<String> kTanyaPinnedTypes = ['ayah', 'tafsir'];

/// Remaining Tanya groups, listed tie-break order (highest score first).
const List<String> kTanyaScoreSortedTypes = [
  'dua',
  'quran_dua',
  'asma',
  'theme',
  'science',
  'surah_info',
];

double tanyaBestScore(AiSearchTypeGroup group) {
  var best = 0.0;
  for (final hit in group.hits) {
    if (hit.score > best) best = hit.score;
  }
  return best;
}

int tanyaTieBreakIndex(String type) {
  final i = kTanyaScoreSortedTypes.indexOf(type);
  return i < 0 ? kTanyaScoreSortedTypes.length : i;
}

List<AiSearchTypeGroup> layoutTanyaGroups(List<AiSearchTypeGroup> groups) {
  final byType = <String, AiSearchTypeGroup>{};
  for (final group in groups) {
    if (group.hits.isEmpty) continue;
    byType[group.type] = group;
  }

  final laid = <AiSearchTypeGroup>[];
  for (final type in kTanyaPinnedTypes) {
    final pinned = byType.remove(type);
    if (pinned != null) laid.add(pinned);
  }

  final remaining = byType.values.toList()
    ..sort((a, b) {
      final byScore = tanyaBestScore(b).compareTo(tanyaBestScore(a));
      if (byScore != 0) return byScore;
      return tanyaTieBreakIndex(a.type).compareTo(tanyaTieBreakIndex(b.type));
    });
  laid.addAll(remaining);
  return laid;
}

List<AiSearchHit> tanyaVisibleHits(
  AiSearchTypeGroup group, {
  required bool expanded,
}) {
  final cap = expanded ? kMaxResultsPerType : kTanyaPreviewPerGroup;
  if (group.hits.length <= cap) return group.hits;
  return group.hits.sublist(0, cap);
}

bool tanyaNeedsSeeAll(AiSearchTypeGroup group) =>
    group.hits.length > kTanyaPreviewPerGroup;
