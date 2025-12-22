import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
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
                    return Center(
                      child: Text(
                        notes.isEmpty
                            ? AppLocalizations.getSubtitleText('notes_empty', settings.appLanguage)
                            : AppLocalizations.getSubtitleText('notes_no_results', settings.appLanguage),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                        future: ref.read(databaseProvider).getVerse(note.surahId, note.ayahNo),
                        builder: (context, verseSnapshot) {
                          final verse = verseSnapshot.data;
                          final arabicText = verse?.arabic ?? '';
                          final translation = _getTranslation(verse, settings.language);
                          
                          return InkWell(
                            onTap: () {
                              ref.read(readerSourceProvider.notifier).state = SurahSource(
                                note.surahId,
                                targetAyahNo: note.ayahNo,
                              );
                              ref.read(targetAyahProvider.notifier).state = note.ayahNo;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReaderScreen(),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.only(
                                bottom: index == filtered.length - 1 ? 0 : 12,
                              ),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${note.surahId}',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  surahInfo.englishName,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                ),
                                              ),
                                              Text(
                                                'Ayah ${note.ayahNo}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          if (arabicText.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: Text(
                                                arabicText,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontFamily: 'UthmanicHafsV22',
                                                      fontFamilyFallback: const ['UthmanicHafs'],
                                                      color: colorScheme.onSurface,
                                                      height: 1.6,
                                                    ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                          if (translation.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              translation,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    height: 1.4,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.primary.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.note_outlined,
                                                  size: 16,
                                                  color: colorScheme.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    note.note,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          color: colorScheme.onSurface,
                                                          height: 1.5,
                                                        ),
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: colorScheme.onSurfaceVariant),
                                      tooltip: 'Edit note',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => NoteEditorDialog(
                                            surahId: note.surahId,
                                            ayahNo: note.ayahNo,
                                            existingNote: note.note,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

