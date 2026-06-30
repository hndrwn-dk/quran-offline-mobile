import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/science_entry.dart';

const _scienceCatalogAsset = 'assets/science/science_catalog.json';

class ScienceCatalog {
  final int version;
  final List<ScienceEntry> entries;

  const ScienceCatalog({required this.version, required this.entries});

  List<ScienceEntry> byCategory(String category) {
    return entries.where((e) => e.category == category).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
  }

  Map<String, List<ScienceEntry>> groupedByCategory() {
    final map = <String, List<ScienceEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sort.compareTo(b.sort));
    }
    const order = ['cosmos', 'biology', 'earth', 'physics'];
    final sorted = <MapEntry<String, List<ScienceEntry>>>[];
    for (final key in order) {
      if (map.containsKey(key)) {
        sorted.add(MapEntry(key, map.remove(key)!));
      }
    }
    sorted.addAll(map.entries);
    return Map.fromEntries(sorted);
  }
}

/// Editorial hero on the Sains category screen (static, not rotated).
const kScienceFeaturedCategoryKey = 'cosmos';

final scienceCatalogProvider = FutureProvider<ScienceCatalog>((ref) async {
  String raw;
  try {
    raw = await rootBundle.loadString(_scienceCatalogAsset);
  } catch (e, st) {
    debugPrint('Science catalog asset missing ($_scienceCatalogAsset): $e\n$st');
    throw FlutterError(
      'Unable to load asset: $_scienceCatalogAsset. '
      'Stop the app completely and run flutter run again (hot reload does not bundle new assets).',
    );
  }

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e, st) {
    debugPrint('Science catalog JSON parse failed: $e\n$st');
    rethrow;
  }
  final items = (json['entries'] as List<dynamic>)
      .map((e) => ScienceEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  final seenIds = <String>{};
  final seenRanges = <String>{};
  for (final entry in items) {
    if (!seenIds.add(entry.id)) {
      throw StateError('Duplicate science id: ${entry.id}');
    }
    final rangeKey = entry.rangeKey();
    if (!seenRanges.add(rangeKey)) {
      throw StateError('Duplicate ayah range: $rangeKey (${entry.id})');
    }
  }

  return ScienceCatalog(
    version: json['version'] as int? ?? 1,
    entries: items,
  );
});
