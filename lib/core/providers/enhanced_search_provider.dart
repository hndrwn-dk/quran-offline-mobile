import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';

class SearchResult {
  final String type; // 'verse', 'surah', 'juz', 'page'
  final String title;
  final String? subtitle;
  final ReaderSource source;

  SearchResult({
    required this.type,
    required this.title,
    this.subtitle,
    required this.source,
  });
}

final enhancedSearchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  
  if (query.isEmpty) return [];

  await Future.delayed(const Duration(milliseconds: 300));
  
  final currentQuery = ref.read(searchQueryProvider);
  if (currentQuery != query) {
    return [];
  }

  final results = <SearchResult>[];
  final queryLower = query.toLowerCase().trim();

  // Search surahs
  final surahsAsync = ref.read(surahNamesProvider);
  surahsAsync.whenData((surahs) {
    for (final surah in surahs) {
      if (surah.id.toString() == query ||
          surah.englishName.toLowerCase().contains(queryLower) ||
          surah.arabicName.contains(query)) {
        results.add(SearchResult(
          type: 'surah',
          title: surah.englishName,
          subtitle: surah.arabicName,
          source: SurahSource(surah.id),
        ));
      }
    }
  });

  // Search Juz (1-30)
  if (queryLower == 'juz' || RegExp(r'^juz\s*\d+$', caseSensitive: false).hasMatch(queryLower)) {
    final juzMatch = RegExp(r'\d+').firstMatch(queryLower);
    if (juzMatch != null) {
      final juzNo = int.tryParse(juzMatch.group(0)!);
      if (juzNo != null && juzNo >= 1 && juzNo <= 30) {
        results.add(SearchResult(
          type: 'juz',
          title: 'Juz $juzNo',
          source: JuzSource(juzNo),
        ));
      }
    }
  } else {
    final juzNo = int.tryParse(query);
    if (juzNo != null && juzNo >= 1 && juzNo <= 30) {
      results.add(SearchResult(
        type: 'juz',
        title: 'Juz $juzNo',
        source: JuzSource(juzNo),
      ));
    }
  }

  // Search Pages (1-604)
  if (queryLower == 'page' || RegExp(r'^page\s*\d+$', caseSensitive: false).hasMatch(queryLower)) {
    final pageMatch = RegExp(r'\d+').firstMatch(queryLower);
    if (pageMatch != null) {
      final pageNo = int.tryParse(pageMatch.group(0)!);
      if (pageNo != null && pageNo >= 1 && pageNo <= 604) {
        results.add(SearchResult(
          type: 'page',
          title: 'Page $pageNo',
          source: PageSource(pageNo),
        ));
      }
    }
  } else {
    final pageNo = int.tryParse(query);
    if (pageNo != null && pageNo >= 1 && pageNo <= 604) {
      results.add(SearchResult(
        type: 'page',
        title: 'Page $pageNo',
        source: PageSource(pageNo),
      ));
    }
  }

  // Search by Ayat Number (format: "X:Y" or "X:Y" with spaces)
  // Examples: "1:1", "2:255", "112:1", "1: 1", "2 : 255"
  final ayatNumberPattern = RegExp(r'^(\d+)\s*:\s*(\d+)$');
  final ayatMatch = ayatNumberPattern.firstMatch(query.trim());
  if (ayatMatch != null) {
    final surahId = int.tryParse(ayatMatch.group(1)!);
    final ayahNo = int.tryParse(ayatMatch.group(2)!);
    
    if (surahId != null && ayahNo != null && surahId >= 1 && surahId <= 114 && ayahNo >= 1) {
      // Validate ayah exists by checking database
      final db = ref.read(databaseProvider);
      final verses = await db.getVersesByRange(surahId, ayahNo, ayahNo);
      
      if (verses.isNotEmpty) {
        // Get surah name for display
        surahsAsync.when(
          data: (surahs) {
            final surah = surahs.firstWhere(
              (s) => s.id == surahId,
              orElse: () => SurahInfo(
                id: surahId,
                arabicName: '',
                englishName: 'Surah $surahId',
                englishMeaning: '',
              ),
            );
            
            results.add(SearchResult(
              type: 'verse',
              title: 'QS $surahId:$ayahNo',
              subtitle: surah.englishName,
              source: SurahSource(surahId, targetAyahNo: ayahNo),
            ));
          },
          loading: () {},
          error: (_, __) {},
        );
      }
    }
  }

  // Search verses (translation text)
  final db = ref.read(databaseProvider);
  final settings = ref.read(settingsProvider);
  final lang = settings.language;
  final verseResults = await db.searchVerses(query, lang);
  
  for (final verse in verseResults) {
    final rawTranslation = verse.trId ?? verse.trEn ?? '';
    results.add(SearchResult(
      type: 'verse',
      title: TranslationCleaner.clean(rawTranslation),
      subtitle: 'QS ${verse.surahId}:${verse.ayahNo}',
      source: SurahSource(verse.surahId),
    ));
  }

  return results;
});

