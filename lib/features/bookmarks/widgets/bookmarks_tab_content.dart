import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/library/widgets/library_empty_state.dart';
import 'package:quran_offline/features/library/widgets/library_item_card.dart';
import 'package:quran_offline/features/bookmarks/open_bookmark.dart';

// Extract from BookmarksScreen for use in TabBarView
class BookmarksTabContent extends ConsumerStatefulWidget {
  const BookmarksTabContent({super.key});

  @override
  ConsumerState<BookmarksTabContent> createState() => _BookmarksTabContentState();
}

enum BookmarkSortBy { date, surah }

class _BookmarksTabContentState extends ConsumerState<BookmarksTabContent> {
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
                      color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearSelection,
                      tooltip: AppLocalizations.getActionTooltip(
                        'cancel_selection',
                        appLanguage,
                      ),
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
                      tooltip: AppLocalizations.getActionTooltip(
                        'select_all',
                        appLanguage,
                      ),
                      onPressed: () {
                        final bookmarks = bookmarksAsync.valueOrNull ?? [];
                        _selectAll(bookmarks);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: AppLocalizations.getActionTooltip(
                        'delete_selected',
                        appLanguage,
                      ),
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
                    return LibraryEmptyState(
                      message: AppLocalizations.getSubtitleText(
                        'bookmarks_empty',
                        settings.appLanguage,
                      ),
                      icon: Icons.bookmark_outline,
                    );
                  }

                  final sortLabel = _sortBy == BookmarkSortBy.date
                      ? AppLocalizations.getSettingsText('sort_date', appLanguage)
                      : AppLocalizations.getSettingsText('sort_surah', appLanguage);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_selectionMode)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            kAppContentHorizontalInset,
                            8,
                            kAppContentHorizontalInset,
                            0,
                          ),
                          child: Text(
                            '${AppLocalizations.getSettingsText('sort_by', appLanguage).toUpperCase()}: ${sortLabel.toUpperCase()}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            kAppContentHorizontalInset,
                            8,
                            kAppContentHorizontalInset,
                            24,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final bookmark = filtered[index];
                            final surahInfo = surahs.firstWhere(
                              (s) => s.id == bookmark.surahId,
                              orElse: () => SurahInfo(
                                id: bookmark.surahId,
                                arabicName: '',
                                englishName: 'Surah ${bookmark.surahId}',
                                englishMeaning: '',
                              ),
                            );
                            final selected =
                                _selectedKeys.contains(_keyFor(bookmark));

                            return FutureBuilder<Verse?>(
                              future: ref
                                  .read(databaseProvider)
                                  .getVerse(bookmark.surahId, bookmark.ayahNo),
                              builder: (context, verseSnapshot) {
                                final verse = verseSnapshot.data;
                                final arabicText = verse?.arabic ?? '';
                                final translation =
                                    _getTranslation(verse, settings.language);

                                return LibraryItemCard(
                                  surahId: bookmark.surahId,
                                  surahName: surahInfo.englishName,
                                  ayahNo: bookmark.ayahNo,
                                  arabicText: arabicText,
                                  translation: translation,
                                  accentColor: bookmark.color != null
                                      ? Color(bookmark.color!)
                                      : null,
                                  selected: selected,
                                  selectionMode: _selectionMode,
                                  onSelectionChanged: (_) =>
                                      _toggleSelection(bookmark),
                                  showChevron: !_selectionMode,
                                  trailingAction: _selectionMode
                                      ? null
                                      : IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          tooltip:
                                              AppLocalizations.getActionTooltip(
                                            'delete_bookmark',
                                            appLanguage,
                                          ),
                                          onPressed: () async {
                                            final confirmed =
                                                await _confirmDelete(
                                              context,
                                              message:
                                                  'Delete this bookmark?',
                                            );
                                            if (!confirmed) return;
                                            await toggleBookmark(
                                              ref,
                                              bookmark.surahId,
                                              bookmark.ayahNo,
                                            );
                                            setState(() {});
                                          },
                                        ),
                                  marginBottom:
                                      index == filtered.length - 1 ? 0 : 8,
                                  onTap: () async {
                                    if (_selectionMode) {
                                      _toggleSelection(bookmark);
                                    } else {
                                      await openBookmarkLocation(
                                        context,
                                        ref,
                                        bookmark,
                                      );
                                    }
                                  },
                                  onLongPress: () {
                                    if (!_selectionMode) {
                                      setState(() {
                                        _selectionMode = true;
                                        _selectedKeys.add(_keyFor(bookmark));
                                      });
                                    } else {
                                      _toggleSelection(bookmark);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
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

