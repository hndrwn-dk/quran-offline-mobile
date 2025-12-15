import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

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

