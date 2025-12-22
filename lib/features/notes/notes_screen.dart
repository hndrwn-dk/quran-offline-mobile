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

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchMode = false;
  int? _filterSurahId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(noteRefreshProvider);
    final notesAsync = ref.watch(notesProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    TextStyle _titleStyle() => Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onSurface.withOpacity(0.08),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.note_rounded,
                size: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notes', style: _titleStyle()),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.getSubtitleText('notes_subtitle', settings.appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: _searchMode
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close search',
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchMode = false;
                    });
                  },
                ),
              ]
            : [
                if (_filterSurahId != null)
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    tooltip: 'Clear filter',
                    onPressed: () {
                      setState(() {
                        _filterSurahId = null;
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: () {
                    setState(() {
                      _searchMode = true;
                    });
                  },
                ),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          if (_searchMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Material(
                elevation: 0,
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.getSubtitleText('notes_search_hint', settings.appLanguage),
                            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // Notes list
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final query = _searchController.text.trim().toLowerCase();

                return surahsAsync.when(
                  data: (surahs) {
                    var filtered = notes.where((note) {
                      // Filter by surah
                      if (_filterSurahId != null && note.surahId != _filterSurahId) {
                        return false;
                      }
                      
                      // Filter by search query
                      if (query.isNotEmpty) {
                        final surahInfo = surahs.firstWhere(
                          (s) => s.id == note.surahId,
                          orElse: () => SurahInfo(
                            id: note.surahId,
                            arabicName: '',
                            englishName: 'Surah ${note.surahId}',
                            englishMeaning: '',
                          ),
                        );
                        final surahName = surahInfo.englishName.toLowerCase();
                        final noteText = note.note.toLowerCase();
                        
                        if (!surahName.contains(query) &&
                            !note.surahId.toString().contains(query) &&
                            !note.ayahNo.toString().contains(query) &&
                            !noteText.contains(query)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();
                    
                    // Sort by surah, then ayah
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
                        final isLast = index == filtered.length - 1;

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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: colorScheme.outlineVariant.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Surah number badge
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${note.surahId}',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Content
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
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        note.note,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              height: 1.5,
                                            ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

