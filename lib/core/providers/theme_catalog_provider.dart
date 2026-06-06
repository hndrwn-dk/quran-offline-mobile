import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/theme_entry.dart';

const _themeCatalogAsset = 'assets/themes/life_themes_catalog.json';

class ThemeCatalog {
  final int version;
  final List<ThemeEntry> entries;

  const ThemeCatalog({required this.version, required this.entries});

  Map<String, List<ThemeEntry>> groupedByCategory() {
    final map = <String, List<ThemeEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sort.compareTo(b.sort));
    }
    const order = [
      'patience',
      'gratitude',
      'provision',
      'family',
      'trials',
      'hope',
      'character',
      'hereafter',
    ];
    final sorted = <MapEntry<String, List<ThemeEntry>>>[];
    for (final key in order) {
      if (map.containsKey(key)) {
        sorted.add(MapEntry(key, map.remove(key)!));
      }
    }
    sorted.addAll(map.entries);
    return Map.fromEntries(sorted);
  }
}

final themeCatalogProvider = FutureProvider<ThemeCatalog>((ref) async {
  String raw;
  try {
    raw = await rootBundle.loadString(_themeCatalogAsset);
  } catch (e, st) {
    debugPrint('Theme catalog asset missing ($_themeCatalogAsset): $e\n$st');
    throw FlutterError(
      'Unable to load asset: $_themeCatalogAsset. '
      'Stop the app completely and run flutter run again (hot reload does not bundle new assets).',
    );
  }

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e, st) {
    debugPrint('Theme catalog JSON parse failed: $e\n$st');
    rethrow;
  }
  final items = (json['entries'] as List<dynamic>)
      .map((e) => ThemeEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  final seenIds = <String>{};
  for (final entry in items) {
    if (!seenIds.add(entry.id)) {
      throw StateError('Duplicate theme id: ${entry.id}');
    }
  }

  return ThemeCatalog(
    version: json['version'] as int? ?? 1,
    entries: items,
  );
});
