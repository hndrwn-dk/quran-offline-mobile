import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/library/widgets/library_empty_state.dart';
import 'package:quran_offline/features/library/widgets/library_item_card.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';
import 'package:quran_offline/features/reader/widgets/note_editor_dialog.dart';

// Extract from NotesScreen for use in TabBarView
class NotesTabContent extends ConsumerStatefulWidget {
  const NotesTabContent({super.key});

  @override
  ConsumerState<NotesTabContent> createState() => _NotesTabContentState();
}

class _NotesTabContentState extends ConsumerState<NotesTabContent> {

  @override
  Widget build(BuildContext context) {
    ref.watch(noteRefreshProvider);
    final notesAsync = ref.watch(notesProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Notes list (no search button - use global search in AppBar)
        Expanded(
          child: notesAsync.when(
            data: (notes) {
              return surahsAsync.when(
                data: (surahs) {
                  // No search filtering in tab view - show all notes
                  var filtered = notes.toList();
                  
                  filtered.sort((a, b) {
                    if (a.surahId != b.surahId) {
                      return a.surahId.compareTo(b.surahId);
                    }
                    return a.ayahNo.compareTo(b.ayahNo);
                  });

                  if (filtered.isEmpty) {
                    return LibraryEmptyState(
                      message: notes.isEmpty
                          ? AppLocalizations.getSubtitleText(
                              'notes_empty',
                              settings.appLanguage,
                            )
                          : AppLocalizations.getSubtitleText(
                              'notes_no_results',
                              settings.appLanguage,
                            ),
                      icon: Icons.note_outlined,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      kAppContentHorizontalInset,
                      8,
                      kAppContentHorizontalInset,
                      24,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final note = filtered[index];
                      final surahInfo = surahs.firstWhere(
                        (s) => s.id == note.surahId,
                        orElse: () => SurahInfo(
                          id: note.surahId,
                          arabicName: '',
                          englishName: 'Surah ${note.surahId}',
                          englishMeaning: '',
                        ),
                      );

                      return FutureBuilder<Verse?>(
                        future: ref
                            .read(databaseProvider)
                            .getVerse(note.surahId, note.ayahNo),
                        builder: (context, verseSnapshot) {
                          final verse = verseSnapshot.data;
                          final arabicText = verse?.arabic ?? '';
                          final translation =
                              _getTranslation(verse, settings.language);

                          return LibraryItemCard(
                            surahId: note.surahId,
                            surahName: surahInfo.englishName,
                            ayahNo: note.ayahNo,
                            arabicText: arabicText,
                            translation: translation,
                            noteText: note.note,
                            marginBottom: index == filtered.length - 1 ? 0 : 8,
                            trailingAction: IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              tooltip: AppLocalizations.getActionTooltip(
                                'edit_note',
                                settings.appLanguage,
                              ),
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => NoteEditorDialog(
                                    surahId: note.surahId,
                                    ayahNo: note.ayahNo,
                                    existingNote: note.note,
                                  ),
                                );
                              },
                            ),
                            showChevron: false,
                            onTap: () {
                              ref.read(readerSourceProvider.notifier).state =
                                  SurahSource(
                                note.surahId,
                                targetAyahNo: note.ayahNo,
                              );
                              ref.read(targetAyahProvider.notifier).state =
                                  note.ayahNo;
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => const ReaderScreen(),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  String _getTranslation(Verse? verse, String language) {
    if (verse == null) return '';
    return switch (language) {
      'en' => verse.trEn ?? '',
      'id' => verse.trId ?? '',
      'zh' => verse.trZh ?? '',
      'ja' => verse.trJa ?? '',
      _ => verse.trId ?? verse.trEn ?? '',
    };
  }
}

