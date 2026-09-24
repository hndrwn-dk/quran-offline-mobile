import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/quran_dua_ayat_entry.dart';

class QuranDuaAyatCatalog {
  final int version;
  final List<QuranDuaAyatEntry> entries;

  const QuranDuaAyatCatalog({required this.version, required this.entries});

  factory QuranDuaAyatCatalog.fromJson(Map<String, dynamic> json) {
    final items = (json['entries'] as List<dynamic>)
        .map((e) => QuranDuaAyatEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final seenIds = <String>{};
    final seenRanges = <String>{};
    for (final entry in items) {
      if (!seenIds.add(entry.id)) {
        throw StateError('Duplicate quran dua ayat id: ${entry.id}');
      }
      final rangeKey = entry.rangeKey();
      if (!seenRanges.add(rangeKey)) {
        throw StateError('Duplicate ayah range: $rangeKey (${entry.id})');
      }
    }

    return QuranDuaAyatCatalog(
      version: json['version'] as int? ?? 1,
      entries: items,
    );
  }
}

final quranDuaAyatCatalogProvider = FutureProvider<QuranDuaAyatCatalog>((ref) async {
  final raw = await rootBundle.loadString(
    'assets/ai/quran_dua_ayat_catalog.json',
  );
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return QuranDuaAyatCatalog.fromJson(json);
});
