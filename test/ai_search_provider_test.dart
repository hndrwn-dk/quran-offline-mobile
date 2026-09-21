import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';

class _FakeIndex extends SearchIndexRepository {
  _FakeIndex({this.hits = const []});

  List<IndexHit> hits;
  final searches = <String>[];

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<IndexHit>> keywordSearch(
    String query, {
    Set<String>? types,
    String lang = 'id',
    int limit = 100,
  }) async {
    searches.add(query);
    var out = hits;
    if (types != null) {
      out = out.where((h) => types.contains(h.type)).toList();
    }
    if (out.length > limit) out = out.sublist(0, limit);
    return out;
  }
}

IndexHit _hit({
  required String id,
  String type = 'ayah',
  double score = 1.0,
  String refKey = '1:1',
  int surah = 1,
  int ayah = 1,
}) {
  return IndexHit(
    docId: id,
    type: type,
    lang: 'id',
    refKey: refKey,
    surah: surah,
    ayahFrom: ayah,
    ayahTo: ayah,
    score: score,
  );
}

ProviderContainer _container({
  required _FakeIndex repo,
  SynonymGroupsLoader? loader,
  String lang = 'id',
}) {
  return ProviderContainer(
    overrides: [
      searchIndexRepositoryProvider.overrideWith((ref) => repo),
      aiSearchLangProvider.overrideWith((ref) => lang),
      synonymGroupsLoaderProvider.overrideWith(
        (ref) => loader ?? (() async => <List<String>>[]),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('below-threshold query returns empty', () async {
    final repo = _FakeIndex(
      hits: [
        _hit(id: 'ayah:1:1:id', score: 0.24),
        _hit(id: 'ayah:1:2:id', score: 0.10, ayah: 2, refKey: '1:2'),
      ],
    );
    final container = _container(repo: repo);
    addTearDown(container.dispose);
    container.read(searchQueryProvider.notifier).state = 'alpha';

    final results = await container.read(aiSearchResultsProvider.future);
    expect(results.isEmpty, isTrue);
    expect(results.groups, isEmpty);
  });

  test('groups by type and caps at kMaxResultsPerType', () async {
    final ayahHits = [
      for (var i = 1; i <= 6; i++)
        _hit(
          id: 'ayah:1:$i:id',
          type: 'ayah',
          score: 1.0 - (i * 0.01),
          ayah: i,
          refKey: '1:$i',
        ),
    ];
    final duaHits = [
      _hit(id: 'dua:one:id', type: 'dua', score: 0.9, refKey: 'dua:one'),
      _hit(id: 'dua:two:id', type: 'dua', score: 0.8, refKey: 'dua:two'),
    ];
    final repo = _FakeIndex(hits: [...ayahHits, ...duaHits]);
    final container = _container(repo: repo);
    addTearDown(container.dispose);
    container.read(searchQueryProvider.notifier).state = 'alpha';

    final results = await container.read(aiSearchResultsProvider.future);
    expect(results.isEmpty, isFalse);
    expect(results.groups.map((g) => g.type).toList(), ['ayah', 'dua']);
    expect(results.groups[0].hits, hasLength(5));
    expect(results.groups[1].hits, hasLength(2));
    expect(results.groups[0].hits.every((h) => h.refKey.isNotEmpty), isTrue);
    expect(results.groups[1].hits.every((h) => h.refKey.isNotEmpty), isTrue);
    expect(results.groups[0].hits.map((h) => h.docId), isNot(contains('ayah:1:6:id')));
  });

  test('missing synonyms file does not error', () async {
    final repo = _FakeIndex(hits: [_hit(id: 'ayah:1:1:id', score: 1.0)]);
    final container = _container(
      repo: repo,
      loader: () async => throw FlutterError('Unable to load asset: synonyms'),
    );
    addTearDown(container.dispose);
    container.read(searchQueryProvider.notifier).state = 'alpha';

    final results = await container.read(aiSearchResultsProvider.future);
    expect(results.isEmpty, isFalse);
    expect(repo.searches, isNotEmpty);
    expect(repo.searches.single.contains('OR'), isFalse);
  });

  test('stale query is discarded', () async {
    final repo = _FakeIndex(hits: [_hit(id: 'ayah:1:1:id', score: 1.0)]);
    final container = _container(repo: repo);
    addTearDown(container.dispose);

    container.read(searchQueryProvider.notifier).state = 'alpha';
    container.listen(aiSearchResultsProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    container.read(searchQueryProvider.notifier).state = 'beta';
    await container.read(aiSearchResultsProvider.future);

    expect(repo.searches, ['beta']);
  });
}
