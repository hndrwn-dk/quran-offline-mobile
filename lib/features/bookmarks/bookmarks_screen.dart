import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/notes/notes_screen.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

enum BookmarkSortBy { date, surah }

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _selectionMode = false;
  bool _searchMode = false;
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
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete bookmarks?'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
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
        title: _selectionMode
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                  ),
                  const SizedBox(width: 4),
                  Text('${_selectedKeys.length} selected'),
                ],
              )
            : Row(
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
                      Icons.bookmark_rounded,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bookmarks', style: _titleStyle()),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.getSubtitleText('bookmarks_subtitle', settings.appLanguage),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: _selectionMode
            ? [
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
              ]
            : _searchMode
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
                    IconButton(
                      icon: const Icon(Icons.note_outlined),
                      tooltip: 'View notes',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotesScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sort & Filter',
                      onPressed: () => _showSortFilterDialog(context, ref),
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
          // Search bar (shown when _searchMode is true)
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
                            hintText: 'Search bookmarks...',
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
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchController.clear();
                            _searchMode = false;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search,
                            color: colorScheme.surface,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Bookmarks list
          Expanded(
            child: bookmarksAsync.when(
              data: (bookmarks) {
                final query = _searchController.text.trim().toLowerCase();

                return surahsAsync.when(
                  data: (surahs) {
                    // Apply filter
                    var filtered = bookmarks.where((b) {
                      // Filter by search query
                      if (query.isNotEmpty) {
                        final surahName = surahs
                            .firstWhere(
                              (s) => s.id == b.surahId,
                              orElse: () => SurahInfo(id: b.surahId, arabicName: '', englishName: 'Surah ${b.surahId}', englishMeaning: ''),
                            )
                            .englishName
                            .toLowerCase();
                        if (!surahName.contains(query) &&
                            !b.surahId.toString().contains(query) &&
                            !b.ayahNo.toString().contains(query)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();
                    
                    // Apply sort
                    filtered = filtered.toList()..sort((a, b) {
                      switch (_sortBy) {
                        case BookmarkSortBy.date:
                          return b.createdAt.compareTo(a.createdAt); // Newest first
                        case BookmarkSortBy.surah:
                          if (a.surahId != b.surahId) {
                            return a.surahId.compareTo(b.surahId);
                          }
                          return a.ayahNo.compareTo(b.ayahNo);
                      }
                    });

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No bookmarks yet'),
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
                        final isLast = index == filtered.length - 1;

                        return InkWell(
                          onTap: () async {
                            if (_selectionMode) {
                              _toggleSelection(bookmark);
                            } else {
                              // Get page number for this ayah
                              final db = ref.read(databaseProvider);
                              final pageNo = await db.getPageForAyah(bookmark.surahId, bookmark.ayahNo);
                              
                              if (pageNo != null) {
                                // Navigate to Mushaf mode with pageNo + surahId + ayahNo
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
                                // Fallback to Surah mode if page not found
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
                              _showBookmarkActions(context, bookmark);
                            } else {
                              _toggleSelection(bookmark);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primaryContainer.withOpacity(0.35)
                                  : null,
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: selected
                                            ? colorScheme.primary.withOpacity(0.5)
                                            : colorScheme.outlineVariant.withOpacity(0.1),
                                        width: selected ? 1.2 : 1,
                                      ),
                                    ),
                            ),
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
                                  const SizedBox(width: 8),
                                ],
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
                                    '${bookmark.surahId}',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // English name and meaning
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
                                        ],
                                      ),
                                      Builder(
                                        builder: (context) {
                                          final meaning = surahInfo.getMeaning(settings.appLanguage);
                                          if (meaning.isEmpty) return const SizedBox.shrink();
                                          return Column(
                                            children: [
                                              const SizedBox(height: 2),
                                              Text(
                                                meaning,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          );
                                        },
                                    ),
                                    ],
                                  ),
                                ),
                                // Arabic name and ayah count
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        surahInfo.arabicName,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontFamily: 'UthmanicHafsV22',
                                              fontFamilyFallback: const ['UthmanicHafs'],
                                              color: colorScheme.onSurface,
                                              height: 1.4,
                                            ),
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ayah ${bookmark.ayahNo}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
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

  void _showBookmarkActions(BuildContext context, Bookmark bookmark) {
    final settings = ref.read(settingsProvider);
    final appLanguage = settings.appLanguage;
    
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppLocalizations.getSettingsText('delete', appLanguage)),
              onTap: () async {
                Navigator.pop(context);
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
        ),
      ),
    );
  }

  void _showSortFilterDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final appLanguage = settings.appLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.getSettingsText('sort_by', appLanguage)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<BookmarkSortBy>(
                title: Text(AppLocalizations.getSettingsText('sort_date', appLanguage)),
                value: BookmarkSortBy.date,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<BookmarkSortBy>(
                title: Text(AppLocalizations.getSettingsText('sort_surah', appLanguage)),
                value: BookmarkSortBy.surah,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sortBy = BookmarkSortBy.date;
              });
            },
            child: Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.getSettingsText('cancel', appLanguage)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }
}

