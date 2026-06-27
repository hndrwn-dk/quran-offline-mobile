import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';

/// Unified Tema hidup category keys (daily duas + life reflections).
const lifeSituationCategoryOrder = [
  'forgiveness',
  'faith',
  'patience',
  'trials',
  'protection',
  'provision',
  'family',
  'gratitude',
  'hope',
  'character',
  'world_hereafter',
];

String normalizeLifeSituationCategory(String key) {
  if (key == 'hereafter') return 'world_hereafter';
  return key;
}

class LifeSituationBucket {
  const LifeSituationBucket({
    required this.categoryKey,
    required this.duas,
    required this.reflections,
  });

  final String categoryKey;
  final List<DuaEntry> duas;
  final List<ThemeEntry> reflections;

  bool get isEmpty => duas.isEmpty && reflections.isEmpty;
}

List<LifeSituationBucket> buildLifeSituationBuckets({
  required DuaCatalog duaCatalog,
  required ThemeCatalog themeCatalog,
}) {
  final duasByTheme = duaCatalog.dailyGroupedByTheme();
  final themesByCategory = themeCatalog.groupedByCategory();

  final merged = <String, LifeSituationBucket>{};

  for (final key in lifeSituationCategoryOrder) {
    merged[key] = LifeSituationBucket(
      categoryKey: key,
      duas: duasByTheme[key] ?? const [],
      reflections: const [],
    );
  }

  for (final entry in themesByCategory.entries) {
    final key = normalizeLifeSituationCategory(entry.key);
    final existing = merged[key];
    if (existing != null) {
      merged[key] = LifeSituationBucket(
        categoryKey: key,
        duas: existing.duas,
        reflections: entry.value,
      );
    } else {
      merged[key] = LifeSituationBucket(
        categoryKey: key,
        duas: const [],
        reflections: entry.value,
      );
    }
  }

  return lifeSituationCategoryOrder
      .map((key) => merged[key]!)
      .where((bucket) => !bucket.isEmpty)
      .toList();
}
