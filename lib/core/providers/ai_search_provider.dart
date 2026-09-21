import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/ai_search/ai_search_config.dart';
import 'package:quran_offline/core/ai_search/id_query_normalizer.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';

const String kSynonymsAssetPath = 'assets/ai/synonyms_id.json';

typedef SynonymGroupsLoader = Future<List<List<String>>> Function();

class AiSearchHit {
  final String docId;
  final String type;
  final String lang;
  final String refKey;
  final int? surah;
  final int? ayahFrom;
  final int? ayahTo;
  final double score;

  const AiSearchHit({
    required this.docId,
    required this.type,
    required this.lang,
    required this.refKey,
    this.surah,
    this.ayahFrom,
    this.ayahTo,
    required this.score,
  });

  factory AiSearchHit.fromIndex(IndexHit hit) {
    return AiSearchHit(
      docId: hit.docId,
      type: hit.type,
      lang: hit.lang,
      refKey: hit.refKey,
      surah: hit.surah,
      ayahFrom: hit.ayahFrom,
      ayahTo: hit.ayahTo,
      score: hit.score,
    );
  }
}

class AiSearchTypeGroup {
  final String type;
  final List<AiSearchHit> hits;

  const AiSearchTypeGroup({required this.type, required this.hits});
}

class AiSearchResults {
  final List<AiSearchTypeGroup> groups;

  const AiSearchResults({required this.groups});

  static const empty = AiSearchResults(groups: []);

  bool get isEmpty => groups.isEmpty;
}

final searchIndexRepositoryProvider = Provider<SearchIndexRepository>((ref) {
  final repo = SearchIndexRepository();
  ref.onDispose(repo.close);
  return repo;
});

final aiSearchLangProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).language;
});

Future<List<List<String>>> loadSynonymGroupsFromAsset() async {
  try {
    final raw = await rootBundle.loadString(kSynonymsAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final groups = json['groups'] as List<dynamic>? ?? [];
    return [
      for (final group in groups)
        [for (final item in group as List<dynamic>) item.toString()],
    ];
  } catch (_) {
    return [];
  }
}

final synonymGroupsLoaderProvider = Provider<SynonymGroupsLoader>((ref) {
  return loadSynonymGroupsFromAsset;
});

String expandQueryWithSynonyms(String normalizedQuery, List<List<String>> groups) {
  if (normalizedQuery.isEmpty || groups.isEmpty) return normalizedQuery;

  final lookup = <String, List<String>>{};
  for (final group in groups) {
    final norms = <String>{};
    for (final term in group) {
      final n = IdQueryNormalizer.normalize(term);
      if (n.isNotEmpty) norms.add(n);
    }
    if (norms.length < 2) continue;
    final list = norms.toList();
    for (final n in list) {
      lookup[n] = list;
    }
  }

  final parts = <String>[];
  for (final token in normalizedQuery.split(' ')) {
    if (token.isEmpty) continue;
    final syn = lookup[token];
    if (syn == null) {
      parts.add(token);
    } else {
      parts.add('(${syn.join(' OR ')})');
    }
  }
  return parts.join(' ');
}

AiSearchResults groupHitsByType(List<IndexHit> hits) {
  final order = <String>[];
  final buckets = <String, List<AiSearchHit>>{};
  for (final hit in hits) {
    // TODO(D0): hybrid scoring 0.4 * bm25_norm + 0.6 * cosine before threshold.
    if (hit.score < kMinScoreKeyword) continue;
    buckets.putIfAbsent(hit.type, () {
      order.add(hit.type);
      return <AiSearchHit>[];
    });
    final list = buckets[hit.type]!;
    if (list.length >= kMaxResultsPerType) continue;
    list.add(AiSearchHit.fromIndex(hit));
  }
  return AiSearchResults(
    groups: [for (final type in order) AiSearchTypeGroup(type: type, hits: buckets[type]!)],
  );
}

final aiSearchResultsProvider = FutureProvider<AiSearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final lang = ref.watch(aiSearchLangProvider);

  if (query.trim().isEmpty) return AiSearchResults.empty;

  await Future<void>.delayed(const Duration(milliseconds: 300));

  final currentQuery = ref.read(searchQueryProvider);
  if (currentQuery != query) {
    return AiSearchResults.empty;
  }

  final normalized = IdQueryNormalizer.normalize(query);
  if (normalized.isEmpty) return AiSearchResults.empty;

  var groups = const <List<String>>[];
  try {
    groups = await ref.read(synonymGroupsLoaderProvider)();
  } catch (_) {
    groups = const [];
  }

  final match = expandQueryWithSynonyms(normalized, groups);
  final repo = ref.read(searchIndexRepositoryProvider);
  await repo.ensureReady();
  final hits = await repo.keywordSearch(match, lang: lang);
  return groupHitsByType(hits);
});
