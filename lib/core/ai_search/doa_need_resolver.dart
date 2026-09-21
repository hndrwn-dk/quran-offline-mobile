import 'dart:math';

import 'package:quran_offline/core/ai_search/ai_search_config.dart';
import 'package:quran_offline/core/ai_search/id_query_normalizer.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/quran_dua_ayat_entry.dart';

enum DoaNeedTier {
  duaCatalog,
  quranDua,
  relatedAyah,
  asma,
  empty,
}

class DoaNeedItem {
  final DoaNeedTier tier;
  final IndexHit hit;
  final double score;

  const DoaNeedItem({
    required this.tier,
    required this.hit,
    required this.score,
  });
}

class DoaNeedResult {
  final List<DoaNeedItem> tier1;
  final List<DoaNeedItem> tier2;
  final List<DoaNeedItem> tier3;
  final List<DoaNeedItem> tier3b;

  const DoaNeedResult({
    required this.tier1,
    required this.tier2,
    required this.tier3,
    required this.tier3b,
  });

  static const empty = DoaNeedResult(
    tier1: [],
    tier2: [],
    tier3: [],
    tier3b: [],
  );

  bool get isEmpty =>
      tier1.isEmpty && tier2.isEmpty && tier3.isEmpty && tier3b.isEmpty;

  DoaNeedTier get tier {
    if (tier1.isNotEmpty) return DoaNeedTier.duaCatalog;
    if (tier2.isNotEmpty) return DoaNeedTier.quranDua;
    if (tier3.isNotEmpty) return DoaNeedTier.relatedAyah;
    if (tier3b.isNotEmpty) return DoaNeedTier.asma;
    return DoaNeedTier.empty;
  }
}

/// Resolves a need query into §6.3 tiers. Keyword-only until GATE D0.
class DoaNeedResolver {
  DoaNeedResolver({
    required SearchIndexRepository index,
    required List<QuranDuaAyatEntry> quranDuaEntries,
    required List<DuaEntry> duaEntries,
  })  : _index = index,
        _quranDuaById = {for (final e in quranDuaEntries) e.id: e},
        _duaIds = {for (final e in duaEntries) e.id};

  final SearchIndexRepository _index;
  final Map<String, QuranDuaAyatEntry> _quranDuaById;
  final Set<String> _duaIds;

  Future<DoaNeedResult> resolve(String needText, {String lang = 'id'}) async {
    final query = IdQueryNormalizer.normalize(needText);
    if (query.isEmpty) return DoaNeedResult.empty;

    await _index.ensureReady();

    final duaHits = await _index.keywordSearch(
      query,
      types: {'dua'},
      lang: lang,
    );
    final quranHits = await _index.keywordSearch(
      query,
      types: {'quran_dua'},
      lang: lang,
    );
    final ayahHits = await _index.keywordSearch(
      query,
      types: {'ayah'},
      lang: lang,
    );
    final asmaHits = await _index.keywordSearch(
      query,
      types: {'asma'},
      lang: lang,
    );

    final tier1 = _take(
      [
        for (final hit in duaHits)
          if (_duaIds.isEmpty || _duaIds.contains(hit.refKey))
            _item(DoaNeedTier.duaCatalog, hit),
      ],
    );
    final tier2 = _take(
      [
        for (final hit in quranHits)
          if (_includeQuranDua(hit)) _item(DoaNeedTier.quranDua, hit),
      ],
    );
    final fillAyah = tier1.isEmpty && tier2.isEmpty;
    final tier3 = fillAyah
        ? _take([
            for (final hit in ayahHits) _item(DoaNeedTier.relatedAyah, hit),
          ])
        : const <DoaNeedItem>[];
    final tier3b = _take([
      for (final hit in asmaHits) _item(DoaNeedTier.asma, hit),
    ]);

    return DoaNeedResult(
      tier1: tier1,
      tier2: tier2,
      tier3: tier3,
      tier3b: tier3b,
    );
  }

  bool _includeQuranDua(IndexHit hit) {
    final entry = _quranDuaById[hit.refKey];
    if (entry == null) return false;
    if (!entry.recommendedToRecite) return false;
    if (entry.inDuaCatalog) return false;
    return true;
  }

  DoaNeedItem? _item(DoaNeedTier tier, IndexHit hit) {
    final score = _score(hit);
    if (score < kMinScoreKeyword) return null;
    return DoaNeedItem(tier: tier, hit: hit, score: score);
  }

  double _score(IndexHit hit) {
    // TODO(D0): hybrid scoring 0.4 * bm25_norm + 0.6 * cosine.
    var score = hit.score;
    if (hit.type == 'dua' || hit.type == 'quran_dua') {
      score = min(1.0, score + 0.05);
    }
    return score;
  }

  List<DoaNeedItem> _take(List<DoaNeedItem?> items) {
    final out = <DoaNeedItem>[];
    for (final item in items) {
      if (item == null) continue;
      out.add(item);
      if (out.length >= kMaxResultsPerType) break;
    }
    return out;
  }
}
