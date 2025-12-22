import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';

// Predefined highlight colors with icons
final highlightColors = [
  Colors.yellow.toARGB32(),
  Colors.orange.toARGB32(),
  Colors.pink.toARGB32(),
  Colors.red.toARGB32(),
  Colors.purple.toARGB32(),
  Colors.blue.toARGB32(),
  Colors.cyan.toARGB32(),
  Colors.green.toARGB32(),
  Colors.teal.toARGB32(),
];

// Get icon for highlight color
IconData getHighlightIcon(int colorValue) {
  final color = Color(colorValue);
  // Match color to icon based on color similarity
  if (color == Colors.yellow || color.value == Colors.yellow.toARGB32()) {
    return Icons.star;
  } else if (color == Colors.orange || color.value == Colors.orange.toARGB32()) {
    return Icons.local_fire_department;
  } else if (color == Colors.pink || color.value == Colors.pink.toARGB32()) {
    return Icons.favorite;
  } else if (color == Colors.red || color.value == Colors.red.toARGB32()) {
    return Icons.priority_high;
  } else if (color == Colors.purple || color.value == Colors.purple.toARGB32()) {
    return Icons.bookmark;
  } else if (color == Colors.blue || color.value == Colors.blue.toARGB32()) {
    return Icons.info;
  } else if (color == Colors.cyan || color.value == Colors.cyan.toARGB32()) {
    return Icons.water_drop;
  } else if (color == Colors.green || color.value == Colors.green.toARGB32()) {
    return Icons.check_circle;
  } else if (color == Colors.teal || color.value == Colors.teal.toARGB32()) {
    return Icons.eco;
  }
  return Icons.format_color_fill;
}

final highlightsProvider = FutureProvider<List<Highlight>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getAllHighlights();
});

final highlightProvider = FutureProvider.family<Highlight?, ({int surahId, int ayahNo})>((ref, params) async {
  final db = ref.read(databaseProvider);
  return await db.getHighlight(params.surahId, params.ayahNo);
});

final highlightsBySurahProvider = FutureProvider.family<List<Highlight>, int>((ref, surahId) async {
  final db = ref.read(databaseProvider);
  return await db.getHighlightsBySurah(surahId);
});

final highlightRefreshProvider = StateProvider<int>((ref) => 0);

Future<void> toggleHighlight(WidgetRef ref, int surahId, int ayahNo, int color) async {
  final db = ref.read(databaseProvider);
  await db.toggleHighlight(surahId, ayahNo, color);
  ref.read(highlightRefreshProvider.notifier).state++;
  ref.invalidate(highlightProvider((surahId: surahId, ayahNo: ayahNo)));
  ref.invalidate(highlightsProvider);
  ref.invalidate(highlightsBySurahProvider(surahId));
}

Future<void> removeHighlight(WidgetRef ref, int surahId, int ayahNo) async {
  final db = ref.read(databaseProvider);
  await db.removeHighlight(surahId, ayahNo);
  ref.read(highlightRefreshProvider.notifier).state++;
  ref.invalidate(highlightProvider((surahId: surahId, ayahNo: ayahNo)));
  ref.invalidate(highlightsProvider);
  ref.invalidate(highlightsBySurahProvider(surahId));
}

