import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/bookmarks/widgets/bookmarks_tab_content.dart';
import 'package:quran_offline/features/highlights/highlights_screen.dart';
import 'package:quran_offline/features/notes/widgets/notes_tab_content.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class MyLibraryScreen extends ConsumerStatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  ConsumerState<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends ConsumerState<MyLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _globalSearchController = TextEditingController();
  bool _globalSearchMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _globalSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
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
                Icons.library_books_rounded,
                size: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Library', style: _titleStyle()),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.getSubtitleText('library_subtitle', appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: _globalSearchMode
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close search',
                  onPressed: () {
                    setState(() {
                      _globalSearchController.clear();
                      _globalSearchMode = false;
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search all',
                  onPressed: () {
                    setState(() {
                      _globalSearchMode = true;
                    });
                  },
                ),
              ],
        bottom: _globalSearchMode
            ? null
            : TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_outline, size: 18),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.getMenuText('bookmarks', appLanguage)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.note_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.getMenuText('notes', appLanguage)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.format_color_fill_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.getMenuText('highlights', appLanguage)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _globalSearchMode
          ? _buildGlobalSearchResults()
          : TabBarView(
              controller: _tabController,
              children: const [
                BookmarksTabContent(),
                NotesTabContent(),
                HighlightsScreen(),
              ],
            ),
    );
  }

  Widget _buildGlobalSearchResults() {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final query = _globalSearchController.text.trim().toLowerCase();

    // Watch all providers
    ref.watch(bookmarkRefreshProvider);
    ref.watch(noteRefreshProvider);
    ref.watch(highlightRefreshProvider);
    
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final notesAsync = ref.watch(notesProvider);
    final highlightsAsync = ref.watch(highlightsProvider);
    final surahsAsync = ref.watch(surahNamesProvider);

    return Column(
      children: [
        // Search bar
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
                      controller: _globalSearchController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.getSubtitleText('library_search_hint', appLanguage),
                        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_globalSearchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _globalSearchController.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        // Search results
        Expanded(
          child: query.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.getSubtitleText('library_search_hint', appLanguage),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : surahsAsync.when(
                  data: (surahs) {
                    return bookmarksAsync.when(
                      data: (bookmarks) {
                        return notesAsync.when(
                          data: (notes) {
                            return highlightsAsync.when(
                              data: (highlights) {
                                // Filter all items
                                final filteredBookmarks = bookmarks.where((b) {
                                  final surahInfo = surahs.firstWhere(
                                    (s) => s.id == b.surahId,
                                    orElse: () => SurahInfo(
                                      id: b.surahId,
                                      arabicName: '',
                                      englishName: 'Surah ${b.surahId}',
                                      englishMeaning: '',
                                    ),
                                  );
                                  final surahName = surahInfo.englishName.toLowerCase();
                                  return surahName.contains(query) ||
                                      b.surahId.toString().contains(query) ||
                                      b.ayahNo.toString().contains(query);
                                }).toList();

                                final filteredNotes = notes.where((note) {
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
                                  return surahName.contains(query) ||
                                      note.surahId.toString().contains(query) ||
                                      note.ayahNo.toString().contains(query) ||
                                      note.note.toLowerCase().contains(query);
                                }).toList();

                                final filteredHighlights = highlights.where((highlight) {
                                  final surahInfo = surahs.firstWhere(
                                    (s) => s.id == highlight.surahId,
                                    orElse: () => SurahInfo(
                                      id: highlight.surahId,
                                      arabicName: '',
                                      englishName: 'Surah ${highlight.surahId}',
                                      englishMeaning: '',
                                    ),
                                  );
                                  final surahName = surahInfo.englishName.toLowerCase();
                                  return surahName.contains(query) ||
                                      highlight.surahId.toString().contains(query) ||
                                      highlight.ayahNo.toString().contains(query);
                                }).toList();

                                final totalResults = filteredBookmarks.length +
                                    filteredNotes.length +
                                    filteredHighlights.length;

                                if (totalResults == 0) {
                                  return Center(
                                    child: Text(
                                      AppLocalizations.getSubtitleText('library_no_results', appLanguage),
                                    ),
                                  );
                                }

                                return ListView(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  children: [
                                    // Bookmarks section
                                    if (filteredBookmarks.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        context,
                                        AppLocalizations.getMenuText('bookmarks', appLanguage),
                                        filteredBookmarks.length,
                                        colorScheme,
                                      ),
                                      ...filteredBookmarks.map((bookmark) => _buildBookmarkItem(
                                            context,
                                            bookmark,
                                            surahs,
                                            settings,
                                            colorScheme,
                                          )),
                                      const SizedBox(height: 16),
                                    ],
                                    // Notes section
                                    if (filteredNotes.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        context,
                                        AppLocalizations.getMenuText('notes', appLanguage),
                                        filteredNotes.length,
                                        colorScheme,
                                      ),
                                      ...filteredNotes.map((note) => _buildNoteItem(
                                            context,
                                            note,
                                            surahs,
                                            settings,
                                            colorScheme,
                                          )),
                                      const SizedBox(height: 16),
                                    ],
                                    // Highlights section
                                    if (filteredHighlights.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        context,
                                        AppLocalizations.getMenuText('highlights', appLanguage),
                                        filteredHighlights.length,
                                        colorScheme,
                                      ),
                                      ...filteredHighlights.map((highlight) => _buildHighlightItem(
                                            context,
                                            highlight,
                                            surahs,
                                            settings,
                                            colorScheme,
                                          )),
                                    ],
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, _) => Center(child: Text('Error: $error')),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Center(child: Text('Error: $error')),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('Error: $error')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkItem(
    BuildContext context,
    Bookmark bookmark,
    List<SurahInfo> surahs,
    AppSettings settings,
    ColorScheme colorScheme,
  ) {
    final surahInfo = surahs.firstWhere(
      (s) => s.id == bookmark.surahId,
      orElse: () => SurahInfo(
        id: bookmark.surahId,
        arabicName: '',
        englishName: 'Surah ${bookmark.surahId}',
        englishMeaning: '',
      ),
    );

    return InkWell(
      onTap: () async {
        final db = ref.read(databaseProvider);
        final pageNo = await db.getPageForAyah(bookmark.surahId, bookmark.ayahNo);
        
        if (pageNo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MushafPageView(
                initialPage: pageNo,
                targetSurahId: bookmark.surahId,
                targetAyahNo: bookmark.ayahNo,
              ),
            ),
          );
        } else {
          ref.read(readerSourceProvider.notifier).state = SurahSource(bookmark.surahId, targetAyahNo: bookmark.ayahNo);
          ref.read(targetAyahProvider.notifier).state = bookmark.ayahNo;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReaderScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bookmark.color != null
                    ? Color(bookmark.color!).withOpacity(0.2)
                    : colorScheme.surfaceVariant,
                shape: BoxShape.circle,
                border: bookmark.color != null
                    ? Border.all(color: Color(bookmark.color!), width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${bookmark.surahId}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: bookmark.color != null
                          ? Color(bookmark.color!)
                          : colorScheme.onSurfaceVariant,
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
                        'Ayah ${bookmark.ayahNo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.bookmark,
              color: colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    Note note,
    List<SurahInfo> surahs,
    AppSettings settings,
    ColorScheme colorScheme,
  ) {
    final surahInfo = surahs.firstWhere(
      (s) => s.id == note.surahId,
      orElse: () => SurahInfo(
        id: note.surahId,
        arabicName: '',
        englishName: 'Surah ${note.surahId}',
        englishMeaning: '',
      ),
    );

    return InkWell(
      onTap: () {
        ref.read(readerSourceProvider.notifier).state = SurahSource(note.surahId, targetAyahNo: note.ayahNo);
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
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.note,
              color: colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(
    BuildContext context,
    Highlight highlight,
    List<SurahInfo> surahs,
    AppSettings settings,
    ColorScheme colorScheme,
  ) {
    final surahInfo = surahs.firstWhere(
      (s) => s.id == highlight.surahId,
      orElse: () => SurahInfo(
        id: highlight.surahId,
        arabicName: '',
        englishName: 'Surah ${highlight.surahId}',
        englishMeaning: '',
      ),
    );
    final highlightColor = Color(highlight.color);

    return InkWell(
      onTap: () {
        ref.read(readerSourceProvider.notifier).state = SurahSource(highlight.surahId, targetAyahNo: highlight.ayahNo);
        ref.read(targetAyahProvider.notifier).state = highlight.ayahNo;
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
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: highlightColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: highlightColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${highlight.surahId}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: highlightColor,
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
                        'Ayah ${highlight.ayahNo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.format_color_fill,
              color: highlightColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

