import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

// Extract from BookmarksScreen for use in TabBarView
class BookmarksTabContent extends ConsumerStatefulWidget {
  const BookmarksTabContent({super.key});

  @override
  ConsumerState<BookmarksTabContent> createState() => _BookmarksTabContentState();
}

enum BookmarkSortBy { date, surah }

class _BookmarksTabContentState extends ConsumerState<BookmarksTabContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _selectionMode = false;
  final Set<String> _selectedKeys = {};
  BookmarkSortBy _sortBy = BookmarkSortBy.date;

  String _keyFor(Bookmark b) => '${b.surahId}:${b.ayahNo}';

  void _toggleSelection(Bookmark b) {
    final key = _keyFor(b);
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
        if (_selectedKeys.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedKeys.add(key);
        _selectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedKeys.clear();
      _selectionMode = false;
    });
  }

  Future<bool> _confirmDelete(BuildContext context, {required String message}) async {
    final settings = ref.read(settingsProvider);
    final appLanguage = settings.appLanguage;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.getSettingsText('delete', appLanguage)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppLocalizations.getSettingsText('cancel', appLanguage)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(AppLocalizations.getSettingsText('delete', appLanguage)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _selectAll(List<Bookmark> items) {
    setState(() {
      _selectedKeys
        ..clear()
        ..addAll(items.map(_keyFor));
      _selectionMode = items.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bookmarkRefreshProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final appLanguage = settings.appLanguage;

    return Stack(
      children: [
        Column(
          children: [
            // Selection mode bar (shown when selection mode is active)
            if (_selectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearSelection,
                      tooltip: 'Cancel selection',
                    ),
                    Expanded(
                      child: Text(
                        '${_selectedKeys.length} ${AppLocalizations.getSettingsText('selected', appLanguage)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: 'Select all',
                      onPressed: () {
                        final bookmarks = bookmarksAsync.valueOrNull ?? [];
                        _selectAll(bookmarks);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete selected',
                      onPressed: () async {
                        final bookmarks = bookmarksAsync.valueOrNull ?? [];
                        final selected = bookmarks
                            .where((b) => _selectedKeys.contains(_keyFor(b)))
                            .toList();
                        if (selected.isEmpty) return;
                        final confirmed = await _confirmDelete(
                          context,
                          message: 'Delete ${selected.length} selected bookmark(s)?',
                        );
                        if (!confirmed) return;
                        await deleteBookmarksBulk(ref, selected);
                        _clearSelection();
                      },
                    ),
                  ],
                ),
              ),
            // Bookmarks list (no search/filter buttons - use global search in AppBar)
            Expanded(
          child: bookmarksAsync.when(
            data: (bookmarks) {
              return surahsAsync.when(
                data: (surahs) {
                  // No filtering - show all bookmarks
                  var filtered = bookmarks.toList();
                  
                  filtered = filtered.toList()..sort((a, b) {
                    switch (_sortBy) {
                      case BookmarkSortBy.date:
                        return b.createdAt.compareTo(a.createdAt);
                      case BookmarkSortBy.surah:
                        if (a.surahId != b.surahId) {
                          return a.surahId.compareTo(b.surahId);
                        }
                        return a.ayahNo.compareTo(b.ayahNo);
                    }
                  });

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.getSubtitleText('bookmarks_empty', settings.appLanguage),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bookmark = filtered[index];
                      final surahInfo = surahs.firstWhere(
                        (s) => s.id == bookmark.surahId,
                        orElse: () => SurahInfo(id: bookmark.surahId, arabicName: '', englishName: 'Surah ${bookmark.surahId}', englishMeaning: ''),
                      );
                      final selected = _selectedKeys.contains(_keyFor(bookmark));

                      return FutureBuilder<Verse?>(
                        future: ref.read(databaseProvider).getVerse(bookmark.surahId, bookmark.ayahNo),
                        builder: (context, verseSnapshot) {
                          final verse = verseSnapshot.data;
                          final arabicText = verse?.arabic ?? '';
                          final translation = _getTranslation(verse, settings.language);
                          
                          return InkWell(
                            onTap: () async {
                              if (_selectionMode) {
                                _toggleSelection(bookmark);
                              } else {
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
                              }
                            },
                            onLongPress: () {
                              if (!_selectionMode) {
                                // Enter selection mode and select this bookmark
                                setState(() {
                                  _selectionMode = true;
                                  _selectedKeys.add(_keyFor(bookmark));
                                });
                              } else {
                                _toggleSelection(bookmark);
                              }
                            },
                            child: Card(
                              margin: EdgeInsets.only(
                                bottom: index == filtered.length - 1 ? 0 : 12,
                              ),
                              elevation: selected ? 4 : 1,
                              color: selected
                                  ? colorScheme.primaryContainer.withOpacity(0.5)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: selected
                                    ? BorderSide(
                                        color: colorScheme.primary.withOpacity(0.5),
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_selectionMode) ...[
                                      Checkbox(
                                        value: selected,
                                        onChanged: (_) => _toggleSelection(bookmark),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${bookmark.surahId}',
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
                                                'Ayah ${bookmark.ayahNo}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Builder(
                                            builder: (context) {
                                              final meaning = surahInfo.getMeaning(settings.appLanguage);
                                              if (meaning.isEmpty) return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  meaning,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.onSurfaceVariant,
                                                      ),
                                                ),
                                              );
                                            },
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
                                        ],
                                      ),
                                    ),
                                    if (!_selectionMode) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: colorScheme.onSurfaceVariant),
                                        tooltip: 'Delete bookmark',
                                        onPressed: () async {
                                          final confirmed = await _confirmDelete(
                                            context,
                                            message: 'Delete this bookmark?',
                                          );
                                          if (!confirmed) return;
                                          await toggleBookmark(ref, bookmark.surahId, bookmark.ayahNo);
                                          setState(() {});
                                        },
                                      ),
                                    ],
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
    ),
    // Floating action button for selection mode (shown when not in selection mode)
    if (!_selectionMode && bookmarksAsync.valueOrNull?.isNotEmpty == true)
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          mini: true,
          onPressed: () {
            setState(() {
              _selectionMode = true;
            });
          },
          tooltip: 'Select bookmarks',
          child: const Icon(Icons.checklist),
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

