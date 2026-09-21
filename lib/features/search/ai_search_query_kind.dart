import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';

enum AiSearchQueryKind { direct, arabic, grouped }

bool isDirectSearchResult(SearchResult result) {
  return result.type == 'surah' ||
      result.type == 'juz' ||
      result.type == 'page' ||
      result.verseMatchKind == SearchVerseMatchKind.reference;
}

AiSearchQueryKind detectAiSearchQueryKind(
  String query,
  List<SearchResult> classic,
) {
  if (ArabicSearchNormalizer.containsArabic(query)) {
    return AiSearchQueryKind.arabic;
  }
  if (classic.any(isDirectSearchResult)) {
    return AiSearchQueryKind.direct;
  }
  return AiSearchQueryKind.grouped;
}

SearchResult? pickDirectSearchResult(List<SearchResult> classic) {
  SearchResult? verseRef;
  SearchResult? surah;
  SearchResult? juz;
  SearchResult? page;
  for (final result in classic) {
    if (result.verseMatchKind == SearchVerseMatchKind.reference) {
      verseRef ??= result;
    } else if (result.type == 'surah') {
      surah ??= result;
    } else if (result.type == 'juz') {
      juz ??= result;
    } else if (result.type == 'page') {
      page ??= result;
    }
  }
  return verseRef ?? surah ?? juz ?? page;
}

List<SearchResult> arabicSearchResults(List<SearchResult> classic) {
  return [
    for (final result in classic)
      if (result.verseMatchKind == SearchVerseMatchKind.arabic) result,
  ];
}

List<SearchResult> translationSearchResults(List<SearchResult> classic) {
  return [
    for (final result in classic)
      if (result.type == 'verse' &&
          result.verseMatchKind == SearchVerseMatchKind.translation)
        result,
  ];
}
