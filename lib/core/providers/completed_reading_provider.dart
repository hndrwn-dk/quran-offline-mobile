import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reading_completion_provider.dart';
import 'package:quran_offline/core/reading/completed_reading.dart';
import 'package:quran_offline/core/reading/reading_completion.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompletedReadingNotifier extends StateNotifier<CompletedReading?> {
  CompletedReadingNotifier() : super(null) {
    _load();
  }

  static const String key = 'completed_reading';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return;
      state = CompletedReading.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // Ignore corrupt legacy data.
    }
  }

  Future<void> markCompleted(CompletedReading record) async {
    state = record;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(record.toJson()));
    } catch (_) {
      // Completion must never break reading.
    }
  }

  Future<void> clear() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // Ignore.
    }
  }
}

final completedReadingProvider =
    StateNotifierProvider<CompletedReadingNotifier, CompletedReading?>((ref) {
  return CompletedReadingNotifier();
});

/// Completion for the Continue card/tap, only when the persisted completion
/// still matches the stored last-read position.
final continueCompletionProvider =
    FutureProvider<ReadingCompletion?>((ref) async {
  final record = ref.watch(completedReadingProvider);
  final lastRead = ref.watch(lastReadProvider);
  if (record == null || lastRead == null) return null;
  if (!record.matches(lastRead)) return null;
  return ref.watch(readingCompletionProvider.future);
});
