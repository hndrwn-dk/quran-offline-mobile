import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/doa_need_resolver.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/quran_dua_ayat_entry.dart';

class _FakeIndex extends SearchIndexRepository {
  _FakeIndex(this.byType);

  final Map<String, List<IndexHit>> byType;

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<IndexHit>> keywordSearch(
    String query, {
    Set<String>? types,
    String lang = 'id',
    int limit = 100,
  }) async {
    if (types == null || types.isEmpty) {
      return byType.values.expand((e) => e).toList();
    }
    return [
      for (final type in types) ...?byType[type],
    ];
  }
}

IndexHit _hit({
  required String id,
  required String type,
  double score = 1.0,
  String? refKey,
}) {
  return IndexHit(
    docId: id,
    type: type,
    lang: 'id',
    refKey: refKey ?? id,
    surah: 2,
    ayahFrom: 1,
    ayahTo: 1,
    score: score,
  );
}

QuranDuaAyatEntry _qdua({
  required String id,
  required bool recommendedToRecite,
  required bool inDuaCatalog,
}) {
  return QuranDuaAyatEntry(
    id: id,
    ref: const DuaAyahRef(surah: 2, from: 1, to: 1),
    tags: const [],
    need: const QuranDuaNeed(id: '', en: ''),
    recommendedToRecite: recommendedToRecite,
    inDuaCatalog: inDuaCatalog,
    duaCatalogIds: const [],
    source: 'test',
  );
}

DuaEntry _dua(String id) {
  const text = LocalizedText(id: 't', en: 't', zh: 't', ja: 't');
  return DuaEntry(
    id: id,
    category: 'daily',
    sort: 1,
    title: text,
    summary: text,
    ayahRefs: const [DuaAyahRef(surah: 2, from: 1, to: 1)],
  );
}

DoaNeedResolver _resolver({
  required Map<String, List<IndexHit>> hits,
  List<QuranDuaAyatEntry> quranDua = const [],
  List<DuaEntry> duas = const [],
}) {
  return DoaNeedResolver(
    index: _FakeIndex(hits),
    quranDuaEntries: quranDua,
    duaEntries: duas,
  );
}

void main() {
  test('tier 1 returns duas_catalog hits', () async {
    final result = await _resolver(
      hits: {
        'dua': [_hit(id: 'dua:one:id', type: 'dua', refKey: 'one')],
      },
      duas: [_dua('one')],
    ).resolve('alpha');
    expect(result.tier, DoaNeedTier.duaCatalog);
    expect(result.tier1.map((e) => e.hit.refKey), ['one']);
    expect(result.tier1.every((e) => e.tier == DoaNeedTier.duaCatalog), isTrue);
    expect(result.tier3, isEmpty);
  });

  test('tier 2 returns recommended quran_dua not in dua catalog', () async {
    final result = await _resolver(
      hits: {
        'quran_dua': [
          _hit(id: 'qdua:qd1:id', type: 'quran_dua', refKey: 'qd1'),
        ],
      },
      quranDua: [
        _qdua(id: 'qd1', recommendedToRecite: true, inDuaCatalog: false),
      ],
    ).resolve('alpha');
    expect(result.tier, DoaNeedTier.quranDua);
    expect(result.tier2.map((e) => e.hit.refKey), ['qd1']);
    expect(result.tier3, isEmpty);
  });

  test('tier 3 ayah only when tiers 1 and 2 are empty', () async {
    final result = await _resolver(
      hits: {
        'ayah': [_hit(id: 'ayah:2:1:id', type: 'ayah', refKey: '2:1')],
      },
    ).resolve('alpha');
    expect(result.tier, DoaNeedTier.relatedAyah);
    expect(result.tier3, isNotEmpty);
    expect(result.tier3.single.tier, DoaNeedTier.relatedAyah);
  });

  test('tier 3b asma appears regardless of other tiers', () async {
    final result = await _resolver(
      hits: {
        'dua': [_hit(id: 'dua:one:id', type: 'dua', refKey: 'one')],
        'asma': [_hit(id: 'asma:17:id', type: 'asma', refKey: '17')],
      },
      duas: [_dua('one')],
    ).resolve('alpha');
    expect(result.tier3b, isNotEmpty);
    expect(result.tier3b.single.tier, DoaNeedTier.asma);
    expect(result.tier1, isNotEmpty);
  });

  test('recommendedToRecite false never appears', () async {
    final result = await _resolver(
      hits: {
        'quran_dua': [
          _hit(id: 'qdua:skip:id', type: 'quran_dua', refKey: 'skip'),
        ],
      },
      quranDua: [
        _qdua(id: 'skip', recommendedToRecite: false, inDuaCatalog: false),
      ],
    ).resolve('alpha');
    expect(result.tier2, isEmpty);
    expect(result.isEmpty, isTrue);
  });

  test('tier 2 excludes inDuaCatalog entries', () async {
    final result = await _resolver(
      hits: {
        'dua': [_hit(id: 'dua:one:id', type: 'dua', refKey: 'one')],
        'quran_dua': [
          _hit(id: 'qdua:dup:id', type: 'quran_dua', refKey: 'dup'),
        ],
      },
      duas: [_dua('one')],
      quranDua: [
        _qdua(id: 'dup', recommendedToRecite: true, inDuaCatalog: true),
      ],
    ).resolve('alpha');
    expect(result.tier1, isNotEmpty);
    expect(result.tier2, isEmpty);
  });

  test('tier 3 suppressed when tier 1 or 2 has results', () async {
    final withTier1 = await _resolver(
      hits: {
        'dua': [_hit(id: 'dua:one:id', type: 'dua', refKey: 'one')],
        'ayah': [_hit(id: 'ayah:2:1:id', type: 'ayah')],
      },
      duas: [_dua('one')],
    ).resolve('alpha');
    expect(withTier1.tier1, isNotEmpty);
    expect(withTier1.tier3, isEmpty);

    final withTier2 = await _resolver(
      hits: {
        'quran_dua': [
          _hit(id: 'qdua:qd1:id', type: 'quran_dua', refKey: 'qd1'),
        ],
        'ayah': [_hit(id: 'ayah:2:1:id', type: 'ayah')],
      },
      quranDua: [
        _qdua(id: 'qd1', recommendedToRecite: true, inDuaCatalog: false),
      ],
    ).resolve('alpha');
    expect(withTier2.tier2, isNotEmpty);
    expect(withTier2.tier3, isEmpty);
  });

  test('below threshold returns empty state', () async {
    final result = await _resolver(
      hits: {
        'dua': [_hit(id: 'dua:one:id', type: 'dua', refKey: 'one', score: 0.10)],
        'ayah': [_hit(id: 'ayah:2:1:id', type: 'ayah', score: 0.10)],
        'asma': [_hit(id: 'asma:1:id', type: 'asma', score: 0.10)],
      },
      duas: [_dua('one')],
    ).resolve('alpha');
    expect(result.isEmpty, isTrue);
    expect(result.tier, DoaNeedTier.empty);
  });
}
