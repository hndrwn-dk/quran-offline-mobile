import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/features/dua/life_situation.dart';

Future<DuaCatalog> _loadDuaCatalog() async {
  final raw = await rootBundle.loadString('assets/duas/duas_catalog.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final items = (json['entries'] as List<dynamic>)
      .map((e) => DuaEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  return DuaCatalog(version: json['version'] as int? ?? 1, entries: items);
}

Future<ThemeCatalog> _loadThemeCatalog() async {
  final raw =
      await rootBundle.loadString('assets/themes/life_themes_catalog.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final items = (json['entries'] as List<dynamic>)
      .map((e) => ThemeEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  return ThemeCatalog(version: json['version'] as int? ?? 1, entries: items);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildLifeSituationBuckets merges daily duas and reflections', () async {
    final duaCatalog = await _loadDuaCatalog();
    final themeCatalog = await _loadThemeCatalog();
    final buckets = buildLifeSituationBuckets(
      duaCatalog: duaCatalog,
      themeCatalog: themeCatalog,
    );

    expect(buckets, isNotEmpty);
    var lastIndex = -1;
    for (final bucket in buckets) {
      final index = lifeSituationCategoryOrder.indexOf(bucket.categoryKey);
      expect(index, greaterThan(lastIndex));
      lastIndex = index;
    }

    final trials = buckets.firstWhere((b) => b.categoryKey == 'trials');
    expect(trials.duas, isNotEmpty);
    expect(trials.reflections, isNotEmpty);

    final hereafter =
        buckets.firstWhere((b) => b.categoryKey == 'world_hereafter');
    expect(hereafter.duas, isNotEmpty);
    expect(hereafter.reflections, isNotEmpty);

    final totalDuas =
        buckets.fold<int>(0, (sum, bucket) => sum + bucket.duas.length);
    final totalReflections = buckets.fold<int>(
      0,
      (sum, bucket) => sum + bucket.reflections.length,
    );
    expect(totalDuas, duaCatalog.byCategory('daily').length);
    expect(totalReflections, themeCatalog.entries.length);
  });

  test('normalizeLifeSituationCategory maps hereafter to world_hereafter', () {
    expect(normalizeLifeSituationCategory('hereafter'), 'world_hereafter');
    expect(normalizeLifeSituationCategory('trials'), 'trials');
  });
}
