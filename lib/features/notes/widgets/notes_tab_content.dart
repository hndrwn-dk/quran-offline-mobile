import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_surface_card.dart';
import 'package:quran_offline/core/widgets/undoable_dismissible.dart';
import 'package:quran_offline/features/library/library_index.dart';
import 'package:quran_offline/features/library/library_relative_time.dart';
import 'package:quran_offline/features/library/verse_translation.dart';
import 'package:quran_offline/features/library/widgets/library_action_sheet.dart';
import 'package:quran_offline/features/library/widgets/library_empty_state.dart';
import 'package:quran_offline/features/library/widgets/library_marked_text.dart';
import 'package:quran_offline/features/reader/widgets/note_editor_dialog.dart';

class NotesTabContent extends ConsumerStatefulWidget {
  const NotesTabContent({super.key, this.query = ''});

  final String query;

  @override
  ConsumerState<NotesTabContent> createState() => _NotesTabContentState();
}

class _NotesTabContentState extends ConsumerState<NotesTabContent> {
  final Set<String> _hidden = {};

  String _keyFor(Note note) => 'note:${note.surahId}:${note.ayahNo}';

  @override
  Widget build(BuildContext context) {
    ref.watch(noteRefreshProvider);
    final notesAsync = ref.watch(notesProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;

    return notesAsync.when(
      data: (notes) {
        return surahsAsync.when(
          data: (surahs) {
            final visible = notes.where((note) => !_hidden.contains(_keyFor(note))).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            if (visible.isEmpty) {
              return LibraryEmptyState(
                message: AppLocalizations.getSubtitleText('notes_empty', lang),
                icon: Icons.edit_note_outlined,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final note = visible[index];
                final surah = librarySurah(surahs, note.surahId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NoteCard(
                    note: note,
                    surah: surah,
                    language: settings.language,
                    appLanguage: lang,
                    query: widget.query,
                    onDelete: () => _delete(note, lang),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _delete(Note note, String lang) {
    beginLibraryUndoDelete(
      isMounted: () => mounted,
      setState: setState,
      hidden: _hidden,
      entryKey: _keyFor(note),
      context: context,
      message: AppLocalizations.libraryDeleted('note', lang),
      undoLabel: AppLocalizations.libraryUndo(lang),
      delete: () => deleteNote(ref, note.surahId, note.ayahNo),
      restore: () => restoreNoteEntry(ref, note),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({
    required this.note,
    required this.surah,
    required this.language,
    required this.appLanguage,
    required this.query,
    required this.onDelete,
  });

  final Note note;
  final SurahInfo surah;
  final String language;
  final String appLanguage;
  final String query;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<Verse?>(
      future: ref.read(databaseProvider).getVerse(note.surahId, note.ayahNo),
      builder: (context, snapshot) {
        final verse = snapshot.data;
        final arabic = verse?.arabic ?? '';
        final translation = verseTranslation(verse, language);
        final when = formatLibraryRelativeTime(note.updatedAt, DateTime.now(), appLanguage);
        final copyText = libraryCopyText(
          surahName: surah.englishName,
          surahId: note.surahId,
          ayahNo: note.ayahNo,
          arabic: arabic,
          translation: translation,
          note: note.note,
        );
        final titleStyle = libraryMetaStyle(context);

        return UndoableDismissible(
          dismissKey: ValueKey('note-${note.surahId}-${note.ayahNo}'),
          backgroundLabel: AppLocalizations.librarySwipeDelete(appLanguage),
          borderRadius: AppSurfaceCard.borderRadius,
          onDismissed: onDelete,
          child: AppSurfaceCard(
            onTap: () => openLibraryReader(context, ref, note.surahId, note.ayahNo),
            onLongPress: () {
                showLibraryActionSheet(
                  context: context,
                  language: appLanguage,
                  title: 'CATATAN · QS ${note.surahId}:${note.ayahNo}',
                  preview: note.note,
                  copyLabel: AppLocalizations.libraryCopyVerseAndNote(appLanguage),
                  deleteLabel: AppLocalizations.libraryDeleteAction('note', appLanguage),
                  onOpen: () => openLibraryReader(context, ref, note.surahId, note.ayahNo),
                  onEdit: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => NoteEditorDialog(
                        surahId: note.surahId,
                        ayahNo: note.ayahNo,
                        existingNote: note.note,
                      ),
                    );
                  },
                  onCopy: () => copyLibraryText(copyText),
                  onDelete: onDelete,
                );
              },
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LibraryMarkedText(
                            text: '${surah.englishName} · QS ${note.surahId}:${note.ayahNo}',
                            query: query,
                            maxLines: 1,
                            style: titleStyle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          when,
                          style: libraryMetaStyle(context),
                        ),
                      ],
                    ),
                    LibraryArabicLine(arabic: arabic, query: query, fontSize: 20),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LibraryMarkedText(
                                text: note.note,
                                query: query,
                                maxLines: 4,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
            ),
          ),
        );
      },
    );
  }
}
