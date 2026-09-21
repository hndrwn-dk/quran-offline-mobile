import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/ai_search/ai_search_config.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/search/widgets/ai_result_card.dart';

/// Shared-ref related hits. Deterministic; no similarity / hybrid score.
/// TODO(D0): do not add cosine ranking here.
List<AiSearchHit> relatedHitsFromDocIds(
  List<String> docIds, {
  required int surah,
  required int ayah,
}) {
  final hits = <AiSearchHit>[];
  for (final id in docIds) {
    final hit = _parseDocId(id, surah: surah, ayah: ayah);
    if (hit != null) hits.add(hit);
  }
  return hits;
}

AiSearchHit? _parseDocId(
  String docId, {
  required int surah,
  required int ayah,
}) {
  final parts = docId.split(':');
  if (parts.isEmpty) return null;
  switch (parts[0]) {
    case 'ayah':
      if (parts.length >= 3 &&
          parts[1] == '$surah' &&
          parts[2] == '$ayah') {
        return null;
      }
      return AiSearchHit(
        docId: docId,
        type: 'ayah',
        lang: parts.length > 3 ? parts[3] : 'id',
        refKey: parts.length >= 3 ? '${parts[1]}:${parts[2]}' : docId,
        surah: parts.length > 1 ? int.tryParse(parts[1]) : null,
        ayahFrom: parts.length > 2 ? int.tryParse(parts[2]) : null,
        ayahTo: parts.length > 2 ? int.tryParse(parts[2]) : null,
        score: 1.0,
      );
    case 'tafsir':
      return AiSearchHit(
        docId: docId,
        type: 'tafsir',
        lang: parts.length > 1 ? parts[1] : 'id',
        refKey: parts.length >= 4 ? '${parts[2]}:${parts[3]}' : docId,
        surah: parts.length > 2 ? int.tryParse(parts[2]) : null,
        ayahFrom: parts.length > 3 ? int.tryParse(parts[3]) : null,
        ayahTo: parts.length > 3 ? int.tryParse(parts[3]) : null,
        score: 1.0,
      );
    case 'surah':
      return AiSearchHit(
        docId: docId,
        type: 'surah_info',
        lang: parts.length > 2 ? parts[2] : 'id',
        refKey: parts.length > 1 ? parts[1] : docId,
        surah: parts.length > 1 ? int.tryParse(parts[1]) : null,
        score: 1.0,
      );
    case 'dua':
      return AiSearchHit(
        docId: docId,
        type: 'dua',
        lang: parts.length > 2 ? parts[2] : 'id',
        refKey: parts.length > 1 ? parts[1] : docId,
        surah: surah,
        ayahFrom: ayah,
        ayahTo: ayah,
        score: 1.0,
      );
    case 'sci':
      return AiSearchHit(
        docId: docId,
        type: 'science',
        lang: parts.length > 2 ? parts[2] : 'id',
        refKey: parts.length > 1 ? parts[1] : docId,
        surah: surah,
        ayahFrom: ayah,
        ayahTo: ayah,
        score: 1.0,
      );
    case 'theme':
      return AiSearchHit(
        docId: docId,
        type: 'theme',
        lang: parts.length > 2 ? parts[2] : 'id',
        refKey: parts.length > 1 ? parts[1] : docId,
        surah: surah,
        ayahFrom: ayah,
        ayahTo: ayah,
        score: 1.0,
      );
    case 'asma':
      return AiSearchHit(
        docId: docId,
        type: 'asma',
        lang: parts.length > 2 ? parts[2] : 'id',
        refKey: parts.length > 1 ? parts[1] : docId,
        surah: surah,
        ayahFrom: ayah,
        ayahTo: ayah,
        score: 1.0,
      );
    case 'qdua':
      return AiSearchHit(
        docId: docId,
        type: 'quran_dua',
        lang: parts.length > 2 ? parts[2] : 'id',
        refKey: parts.length > 1 ? parts[1] : docId,
        surah: surah,
        ayahFrom: ayah,
        ayahTo: ayah,
        score: 1.0,
      );
    default:
      return null;
  }
}

Map<String, List<AiSearchHit>> groupRelatedHits(List<AiSearchHit> hits) {
  final order = <String>[];
  final buckets = <String, List<AiSearchHit>>{};
  for (final hit in hits) {
    buckets.putIfAbsent(hit.type, () {
      order.add(hit.type);
      return <AiSearchHit>[];
    });
    final list = buckets[hit.type]!;
    if (list.length >= kMaxResultsPerType) continue;
    list.add(hit);
  }
  return {for (final type in order) type: buckets[type]!};
}

Future<void> showRelatedContentSheet({
  required BuildContext context,
  required int surah,
  required int ayah,
  required String lang,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => RelatedContentSheet(
      surah: surah,
      ayah: ayah,
      lang: lang,
    ),
  );
}

class RelatedContentSheet extends ConsumerWidget {
  const RelatedContentSheet({
    super.key,
    required this.surah,
    required this.ayah,
    required this.lang,
  });

  final int surah;
  final int ayah;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<String>>(
      future: _loadIds(ref),
      builder: (context, snapshot) {
        final ids = snapshot.data ?? const <String>[];
        final groups = groupRelatedHits(
          relatedHitsFromDocIds(ids, surah: surah, ayah: ayah),
        );
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    AppLocalizations.getRelatedContentTitle(lang),
                    key: const Key('related_content_title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      AppLocalizations.getRelatedContentEmpty(lang),
                      key: const Key('related_content_empty'),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              AppLocalizations.getAiSearchTypeLabel(
                                entry.key,
                                lang,
                              ),
                              key: Key('related_group_${entry.key}'),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          for (final hit in entry.value)
                            AiSearchHitCard(hit: hit, lang: lang),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Future<List<String>> _loadIds(WidgetRef ref) async {
    final repo = ref.read(searchIndexRepositoryProvider);
    await repo.ensureReady();
    return repo.relatedDocIds(surah, ayah);
  }
}
