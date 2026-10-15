import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/undoable_dismissible.dart';
import 'package:quran_offline/features/library/library_search.dart';
import 'package:quran_offline/features/library/verse_translation.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class LibrarySearchRow {
  const LibrarySearchRow({
    required this.item,
    required this.arabicSurahName,
    required this.time,
    this.bookmark,
    this.noteEntry,
    this.highlight,
  });

  final LibrarySearchItem item;
  final String arabicSurahName;
  final DateTime time;
  final Bookmark? bookmark;
  final Note? noteEntry;
  final Highlight? highlight;

  String get entryKey =>
      '${item.kind.name}:${item.surahId}:${item.ayahNo}';
}

final librarySearchIndexProvider =
    FutureProvider<List<LibrarySearchRow>>((ref) async {
  ref.watch(bookmarkRefreshProvider);
  ref.watch(noteRefreshProvider);
  ref.watch(highlightRefreshProvider);
  final db = ref.watch(databaseProvider);
  final lang = ref.watch(settingsProvider).language;
  final bookmarks = await ref.watch(bookmarksProvider.future);
  final notes = await ref.watch(notesProvider.future);
  final highlights = await ref.watch(highlightsProvider.future);
  final surahs = await ref.watch(surahNamesProvider.future);

  final rows = <LibrarySearchRow>[];
  for (final bookmark in bookmarks) {
    final surah = librarySurah(surahs, bookmark.surahId);
    final verse = await db.getVerse(bookmark.surahId, bookmark.ayahNo);
    rows.add(
      LibrarySearchRow(
        item: LibrarySearchItem(
          kind: LibrarySearchKind.bookmark,
          surahId: bookmark.surahId,
          ayahNo: bookmark.ayahNo,
          surahName: surah.englishName,
          arabic: verse?.arabic ?? '',
          translation: verseTranslation(verse, lang),
          note: bookmark.note ?? '',
        ),
        arabicSurahName: surah.arabicName,
        time: bookmark.createdAt,
        bookmark: bookmark,
      ),
    );
  }
  for (final note in notes) {
    final surah = librarySurah(surahs, note.surahId);
    final verse = await db.getVerse(note.surahId, note.ayahNo);
    rows.add(
      LibrarySearchRow(
        item: LibrarySearchItem(
          kind: LibrarySearchKind.note,
          surahId: note.surahId,
          ayahNo: note.ayahNo,
          surahName: surah.englishName,
          arabic: verse?.arabic ?? '',
          translation: verseTranslation(verse, lang),
          note: note.note,
        ),
        arabicSurahName: surah.arabicName,
        time: note.updatedAt,
        noteEntry: note,
      ),
    );
  }
  for (final highlight in highlights) {
    final surah = librarySurah(surahs, highlight.surahId);
    final verse = await db.getVerse(highlight.surahId, highlight.ayahNo);
    rows.add(
      LibrarySearchRow(
        item: LibrarySearchItem(
          kind: LibrarySearchKind.highlight,
          surahId: highlight.surahId,
          ayahNo: highlight.ayahNo,
          surahName: surah.englishName,
          arabic: verse?.arabic ?? '',
          translation: verseTranslation(verse, lang),
          note: '',
        ),
        arabicSurahName: surah.arabicName,
        time: highlight.createdAt,
        highlight: highlight,
      ),
    );
  }
  return rows;
});

SurahInfo librarySurah(List<SurahInfo> surahs, int surahId) {
  for (final surah in surahs) {
    if (surah.id == surahId) return surah;
  }
  return SurahInfo(
    id: surahId,
    arabicName: '',
    englishName: 'Surah $surahId',
    englishMeaning: '',
  );
}

String libraryKindKey(LibrarySearchKind kind) {
  return switch (kind) {
    LibrarySearchKind.bookmark => 'bookmark',
    LibrarySearchKind.note => 'note',
    LibrarySearchKind.highlight => 'highlight',
  };
}

String libraryCopyText({
  required String surahName,
  required int surahId,
  required int ayahNo,
  required String arabic,
  required String translation,
  String? note,
}) {
  final lines = <String>[
    '$surahName · QS $surahId:$ayahNo',
    if (arabic.isNotEmpty) arabic,
    if (translation.isNotEmpty) translation,
    if (note != null && note.trim().isNotEmpty) note.trim(),
  ];
  return lines.join('\n');
}

Future<void> copyLibraryText(String text) {
  return Clipboard.setData(ClipboardData(text: text));
}

void beginLibraryUndoDelete({
  required bool Function() isMounted,
  required void Function(VoidCallback) setState,
  required Set<String> hidden,
  required String entryKey,
  required Future<void> Function() delete,
  required Future<void> Function() restore,
  required String message,
  required String undoLabel,
  required BuildContext context,
}) {
  setState(() => hidden.add(entryKey));
  Future<void>(() async {
    try {
      await delete();
    } catch (_) {
      if (isMounted()) setState(() => hidden.remove(entryKey));
      return;
    }
    if (!isMounted() || !context.mounted) return;
    showUndoSnackBar(
      context,
      message: message,
      actionLabel: undoLabel,
      onAction: () {
        if (!isMounted()) return;
        setState(() => hidden.remove(entryKey));
        restore();
      },
    );
  });
}

String libraryDeletedMessage(LibrarySearchKind kind, String language) {
  return AppLocalizations.libraryDeleted(libraryKindKey(kind), language);
}

void openLibraryReader(
  BuildContext context,
  WidgetRef ref,
  int surahId,
  int ayahNo,
) {
  ref.read(readerSourceProvider.notifier).state = SurahSource(
    surahId,
    targetAyahNo: ayahNo,
  );
  ref.read(targetAyahProvider.notifier).state = ayahNo;
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (context) => const ReaderScreen(),
    ),
  );
}
