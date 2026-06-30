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
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/bookmarks/widgets/bookmarks_tab_content.dart';
import 'package:quran_offline/features/highlights/highlights_screen.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/library/widgets/library_item_card.dart';
import 'package:quran_offline/features/library/widgets/library_segment_tabs.dart';
import 'package:quran_offline/features/library/widgets/library_stats_row.dart';
import 'package:quran_offline/features/notes/widgets/notes_tab_content.dart';
import 'package:quran_offline/features/bookmarks/open_bookmark.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class MyLibraryScreen extends ConsumerStatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  ConsumerState<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends ConsumerState<MyLibraryScreen> {
  int _selectedTab = 0;
  final TextEditingController _globalSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _globalSearchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _globalSearchController.removeListener(_onSearchTextChanged);
    _globalSearchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(librarySubTabProvider, (previous, next) {
      if (next != null && next >= 0 && next < 3) {
        setState(() => _selectedTab = next);
        ref.read(librarySubTabProvider.notifier).state = null;
      }
    });

    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final topTint = HomeBackdrop.topTint(colorScheme);
    final query = _globalSearchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: topTint,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
        backgroundColor: topTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.collections_bookmark,
                size: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.getNavMenuText('library', appLanguage),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.getSubtitleText(
                    'library_subtitle',
                    appLanguage,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: HomeBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LibraryStatsRow(),
            AppSearchFieldInset(
              padding: const EdgeInsets.fromLTRB(
                kAppContentHorizontalInset,
                4,
                kAppContentHorizontalInset,
                8,
              ),
              child: AppSearchField(
                controller: _globalSearchController,
                hintText: AppLocalizations.getSubtitleText(
                  'library_search_hint',
                  appLanguage,
                ),
              ),
            ),
            if (!isSearching)
              LibrarySegmentTabs(
                labels: [
                  AppLocalizations.getMenuText('bookmarks', appLanguage),
                  AppLocalizations.getMenuText('notes', appLanguage),
                  AppLocalizations.getMenuText('highlights', appLanguage),
                ],
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            Expanded(
              child: isSearching
                  ? _buildGlobalSearchResults(query, appLanguage)
                  : IndexedStack(
                      index: _selectedTab,
                      children: const [
                        BookmarksTabContent(),
                        NotesTabContent(),
                        HighlightsScreen(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSearchResults(String query, String appLanguage) {
    ref.watch(bookmarkRefreshProvider);
    ref.watch(noteRefreshProvider);
    ref.watch(highlightRefreshProvider);

    final bookmarksAsync = ref.watch(bookmarksProvider);
    final notesAsync = ref.watch(notesProvider);
    final highlightsAsync = ref.watch(highlightsProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return surahsAsync.when(
      data: (surahs) {
        return bookmarksAsync.when(
          data: (bookmarks) {
            return notesAsync.when(
              data: (notes) {
                return highlightsAsync.when(
                  data: (highlights) {
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
                          AppLocalizations.getSubtitleText(
                            'library_no_results',
                            appLanguage,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        kAppContentHorizontalInset,
                        0,
                        kAppContentHorizontalInset,
                        24,
                      ),
                      children: [
                        if (filteredBookmarks.isNotEmpty) ...[
                          _buildSectionHeader(
                            AppLocalizations.getMenuText(
                              'bookmarks',
                              appLanguage,
                            ),
                            filteredBookmarks.length,
                            colorScheme,
                          ),
                          ...filteredBookmarks.map(
                            (bookmark) => _buildSearchBookmarkItem(
                              bookmark,
                              surahs,
                              colorScheme,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (filteredNotes.isNotEmpty) ...[
                          _buildSectionHeader(
                            AppLocalizations.getMenuText('notes', appLanguage),
                            filteredNotes.length,
                            colorScheme,
                          ),
                          ...filteredNotes.map(
                            (note) => _buildSearchNoteItem(
                              note,
                              surahs,
                              colorScheme,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (filteredHighlights.isNotEmpty) ...[
                          _buildSectionHeader(
                            AppLocalizations.getMenuText(
                              'highlights',
                              appLanguage,
                            ),
                            filteredHighlights.length,
                            colorScheme,
                          ),
                          ...filteredHighlights.map(
                            (highlight) => _buildSearchHighlightItem(
                              highlight,
                              surahs,
                              colorScheme,
                            ),
                          ),
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
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBookmarkItem(
    Bookmark bookmark,
    List<SurahInfo> surahs,
    ColorScheme colorScheme,
  ) {
    final surahInfo = _surahFor(surahs, bookmark.surahId);
    final accent = bookmark.color != null ? Color(bookmark.color!) : null;

    return LibraryItemCard(
      surahId: bookmark.surahId,
      surahName: surahInfo.englishName,
      ayahNo: bookmark.ayahNo,
      accentColor: accent,
      onTap: () => _openBookmark(bookmark),
    );
  }

  Widget _buildSearchNoteItem(
    Note note,
    List<SurahInfo> surahs,
    ColorScheme colorScheme,
  ) {
    final surahInfo = _surahFor(surahs, note.surahId);

    return LibraryItemCard(
      surahId: note.surahId,
      surahName: surahInfo.englishName,
      ayahNo: note.ayahNo,
      noteText: note.note,
      onTap: () => _openNote(note),
    );
  }

  Widget _buildSearchHighlightItem(
    Highlight highlight,
    List<SurahInfo> surahs,
    ColorScheme colorScheme,
  ) {
    final surahInfo = _surahFor(surahs, highlight.surahId);
    final highlightColor = highlightDisplayColor(highlight.color);

    return LibraryItemCard(
      surahId: highlight.surahId,
      surahName: surahInfo.englishName,
      ayahNo: highlight.ayahNo,
      accentColor: highlightColor,
      onTap: () => _openHighlight(highlight),
    );
  }

  SurahInfo _surahFor(List<SurahInfo> surahs, int surahId) {
    return surahs.firstWhere(
      (s) => s.id == surahId,
      orElse: () => SurahInfo(
        id: surahId,
        arabicName: '',
        englishName: 'Surah $surahId',
        englishMeaning: '',
      ),
    );
  }

  Future<void> _openBookmark(Bookmark bookmark) async {
    await openBookmarkLocation(context, ref, bookmark);
  }

  void _openNote(Note note) {
    ref.read(readerSourceProvider.notifier).state =
        SurahSource(note.surahId, targetAyahNo: note.ayahNo);
    ref.read(targetAyahProvider.notifier).state = note.ayahNo;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ReaderScreen(),
      ),
    );
  }

  void _openHighlight(Highlight highlight) {
    ref.read(readerSourceProvider.notifier).state =
        SurahSource(highlight.surahId, targetAyahNo: highlight.ayahNo);
    ref.read(targetAyahProvider.notifier).state = highlight.ayahNo;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ReaderScreen(),
      ),
    );
  }
}
