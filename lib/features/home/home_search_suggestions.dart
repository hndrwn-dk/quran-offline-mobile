import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/quran_dua_ayat_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// A Home search chip sourced from a reviewed quran-dua tag.
class HomeSearchSuggestion {
  const HomeSearchSuggestion(this.tag);

  final String tag;

  String label(String language) =>
      AppLocalizations.getHomeSearchChipLabel(tag, language);

  String query(String language) =>
      AppLocalizations.getHomeSearchChipQuery(tag, language);
}

const homeSearchSuggestions = [
  HomeSearchSuggestion('sabar'),
  HomeSearchSuggestion('syukur'),
  HomeSearchSuggestion('rezeki'),
  HomeSearchSuggestion('orangtua'),
];

/// Only shows chips whose tag exists in the reviewed quran-dua catalog.
final homeSearchSuggestionsProvider =
    FutureProvider<List<HomeSearchSuggestion>>((ref) async {
  final catalog = await ref.watch(quranDuaAyatCatalogProvider.future);
  final tags = <String>{
    for (final entry in catalog.entries) ...entry.tags,
  };
  return [
    for (final suggestion in homeSearchSuggestions)
      if (tags.contains(suggestion.tag)) suggestion,
  ];
});
