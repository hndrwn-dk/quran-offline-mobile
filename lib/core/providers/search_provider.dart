import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Incremented by Home to focus the Cari field when it opens.
final searchFocusRequestProvider = StateProvider<int>((ref) => 0);

void openSearchTab(WidgetRef ref, {String? query, bool focus = true}) {
  if (query != null) {
    ref.read(searchQueryProvider.notifier).state = query;
  }
  ref.read(currentTabProvider.notifier).state = AppTab.search;
  if (focus) {
    ref.read(searchFocusRequestProvider.notifier).state =
        ref.read(searchFocusRequestProvider) + 1;
  }
}

final searchResultsProvider = FutureProvider<List<Verse>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  
  if (query.isEmpty) return [];

  await Future.delayed(const Duration(milliseconds: 300));
  
  final currentQuery = ref.read(searchQueryProvider);
  if (currentQuery != query) {
    return [];
  }

  final db = ref.read(databaseProvider);
  final settings = ref.read(settingsProvider);
  final lang = settings.language;

  final results = await db.searchVerses(query, lang);
  return results;
});

