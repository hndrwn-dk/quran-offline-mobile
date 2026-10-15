import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getAllNotes();
});

final noteProvider = FutureProvider.family<Note?, ({int surahId, int ayahNo})>((ref, params) async {
  final db = ref.read(databaseProvider);
  return await db.getNote(params.surahId, params.ayahNo);
});

final notesBySurahProvider = FutureProvider.family<List<Note>, int>((ref, surahId) async {
  final db = ref.read(databaseProvider);
  return await db.getNotesBySurah(surahId);
});

final noteRefreshProvider = StateProvider<int>((ref) => 0);

Future<void> saveNote(WidgetRef ref, int surahId, int ayahNo, String noteText) async {
  final db = ref.read(databaseProvider);
  await db.saveNote(surahId, ayahNo, noteText);
  ref.read(noteRefreshProvider.notifier).state++;
  ref.invalidate(noteProvider((surahId: surahId, ayahNo: ayahNo)));
  ref.invalidate(notesProvider);
  ref.invalidate(notesBySurahProvider(surahId));
}

Future<void> deleteNote(WidgetRef ref, int surahId, int ayahNo) async {
  final db = ref.read(databaseProvider);
  await db.deleteNote(surahId, ayahNo);
  ref.read(noteRefreshProvider.notifier).state++;
  ref.invalidate(noteProvider((surahId: surahId, ayahNo: ayahNo)));
  ref.invalidate(notesProvider);
  ref.invalidate(notesBySurahProvider(surahId));
}

