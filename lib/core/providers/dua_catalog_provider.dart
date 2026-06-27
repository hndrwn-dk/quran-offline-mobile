import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/dua_entry.dart';

class DuaCatalog {
  final int version;
  final List<DuaEntry> entries;

  const DuaCatalog({required this.version, required this.entries});

  List<DuaEntry> byCategory(String category) {
    return entries.where((e) => e.category == category).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
  }

  Map<String, List<DuaEntry>> prophetsGrouped() {
    final map = <String, List<DuaEntry>>{};
    for (final e in entries.where((e) => e.category == 'prophet')) {
      final key = e.prophet ?? 'other';
      map.putIfAbsent(key, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sort.compareTo(b.sort));
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.value.first.sort.compareTo(b.value.first.sort)),
    );
  }

  Map<String, List<DuaEntry>> dailyGroupedByTheme() {
    final map = <String, List<DuaEntry>>{};
    for (final e in entries.where((e) => e.category == 'daily')) {
      final key = e.theme;
      if (key == null || key.isEmpty) continue;
      map.putIfAbsent(key, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sort.compareTo(b.sort));
    }
    const order = [
      'forgiveness',
      'faith',
      'trials',
      'protection',
      'provision',
      'family',
      'gratitude',
      'world_hereafter',
    ];
    final sorted = <MapEntry<String, List<DuaEntry>>>[];
    for (final key in order) {
      if (map.containsKey(key)) {
        sorted.add(MapEntry(key, map.remove(key)!));
      }
    }
    sorted.addAll(map.entries);
    return Map.fromEntries(sorted);
  }
}

final duaCatalogProvider = FutureProvider<DuaCatalog>((ref) async {
  final raw = await rootBundle.loadString('assets/duas/duas_catalog.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final items = (json['entries'] as List<dynamic>)
      .map((e) => DuaEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  final seenIds = <String>{};
  final seenRanges = <String>{};
  for (final entry in items) {
    if (!seenIds.add(entry.id)) {
      throw StateError('Duplicate dua id: ${entry.id}');
    }
    final rangeKey = entry.rangeKey();
    if (!seenRanges.add(rangeKey)) {
      throw StateError('Duplicate ayah range: $rangeKey (${entry.id})');
    }
  }

  return DuaCatalog(
    version: json['version'] as int? ?? 1,
    entries: items,
  );
});
