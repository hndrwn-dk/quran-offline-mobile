import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';

class QuickSearchResult {
  final String type; // 'surah', 'juz', 'page'
  final String title;
  final String? subtitle;
  final ReaderSource source;

  QuickSearchResult({
    required this.type,
    required this.title,
    this.subtitle,
    required this.source,
  });
}

final quickSearchQueryProvider = StateProvider<String>((ref) => '');

final quickSearchResultsProvider = FutureProvider<List<QuickSearchResult>>((ref) async {
  final query = ref.watch(quickSearchQueryProvider);
  
  if (query.isEmpty) return [];

  await Future.delayed(const Duration(milliseconds: 300));
  
  final currentQuery = ref.read(quickSearchQueryProvider);
  if (currentQuery != query) {
    return [];
  }

  final results = <QuickSearchResult>[];
  final queryLower = query.toLowerCase().trim();

  // Search surahs
  final surahsAsync = ref.read(surahNamesProvider);
  surahsAsync.whenData((surahs) {
    for (final surah in surahs) {
      // Exact match by number
      if (surah.id.toString() == query) {
        results.insert(0, QuickSearchResult(
          type: 'surah',
          title: surah.englishName,
          subtitle: surah.arabicName,
          source: SurahSource(surah.id),
        ));
      }
      // Partial match by name
      else if (surah.englishName.toLowerCase().contains(queryLower) ||
          surah.arabicName.contains(query)) {
        results.add(QuickSearchResult(
          type: 'surah',
          title: surah.englishName,
          subtitle: surah.arabicName,
          source: SurahSource(surah.id),
        ));
      }
    }
  });

  // Search Juz (1-30)
  final juzNo = int.tryParse(query);
  if (juzNo != null && juzNo >= 1 && juzNo <= 30) {
    results.insert(0, QuickSearchResult(
      type: 'juz',
      title: 'Juz $juzNo',
      source: JuzSource(juzNo),
    ));
  } else if (queryLower.startsWith('juz')) {
    final juzMatch = RegExp(r'\d+').firstMatch(queryLower);
    if (juzMatch != null) {
      final juz = int.tryParse(juzMatch.group(0)!);
      if (juz != null && juz >= 1 && juz <= 30) {
        results.insert(0, QuickSearchResult(
          type: 'juz',
          title: 'Juz $juz',
          source: JuzSource(juz),
        ));
      }
    }
  }

  // Search Pages (1-604)
  final pageNo = int.tryParse(query);
  if (pageNo != null && pageNo >= 1 && pageNo <= 604) {
    results.insert(0, QuickSearchResult(
      type: 'page',
      title: 'Page $pageNo',
      source: PageSource(pageNo),
    ));
  } else if (queryLower.startsWith('page')) {
    final pageMatch = RegExp(r'\d+').firstMatch(queryLower);
    if (pageMatch != null) {
      final page = int.tryParse(pageMatch.group(0)!);
      if (page != null && page >= 1 && page <= 604) {
        results.insert(0, QuickSearchResult(
          type: 'page',
          title: 'Page $page',
          source: PageSource(page),
        ));
      }
    }
  }

  // Limit to max 8 results
  return results.take(8).toList();
});

