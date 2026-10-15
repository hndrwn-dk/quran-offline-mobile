import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/bookmarks/widgets/bookmarks_tab_content.dart';
import 'package:quran_offline/features/highlights/highlights_screen.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/library/widgets/library_search_view.dart';
import 'package:quran_offline/features/library/widgets/library_tab_tiles.dart';
import 'package:quran_offline/features/notes/widgets/notes_tab_content.dart';

class MyLibraryScreen extends ConsumerStatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  ConsumerState<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends ConsumerState<MyLibraryScreen> {
  int _selectedTab = 0;
  bool _searchOpen = false;
  String _debouncedQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = _searchController.text);
    });
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchOpen = false;
      _debouncedQuery = '';
    });
  }

  void _openQuranSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
    ref.read(currentTabProvider.notifier).state = AppTab.search;
    _closeSearch();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(librarySubTabProvider, (previous, next) {
      if (next != null && next >= 0 && next < 3) {
        setState(() {
          _selectedTab = next;
          _searchOpen = false;
        });
        ref.read(librarySubTabProvider.notifier).state = null;
      }
    });

    ref.watch(bookmarkRefreshProvider);
    ref.watch(noteRefreshProvider);
    ref.watch(highlightRefreshProvider);

    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final topTint = HomeBackdrop.topTint(colorScheme);
    final bookmarkCount = ref.watch(bookmarksProvider).valueOrNull?.length ?? 0;
    final noteCount = ref.watch(notesProvider).valueOrNull?.length ?? 0;
    final highlightCount = ref.watch(highlightsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: topTint,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: _searchOpen ? 64 : 68,
        centerTitle: false,
        titleSpacing: _searchOpen ? 0 : 16,
        backgroundColor: topTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
        flexibleSpace: HomeBackdrop.cornerArcFlexibleSpace(colorScheme),
        leading: _searchOpen
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _closeSearch,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: _searchOpen
            ? AppSearchField(
                controller: _searchController,
                focusNode: _searchFocus,
                hintText: AppLocalizations.getSubtitleText(
                  'library_search_hint',
                  appLanguage,
                ),
                onClear: () {
                  _searchDebounce?.cancel();
                  setState(() => _debouncedQuery = '');
                },
              )
            : Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.45,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.collections_bookmark,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.getNavMenuText(
                            'library',
                            appLanguage,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: _searchOpen
            ? const [SizedBox(width: 8)]
            : [
                IconButton(
                  tooltip: AppLocalizations.getSubtitleText(
                    'library_search_hint',
                    appLanguage,
                  ),
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search),
                ),
              ],
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
        child: _searchOpen
            ? LibrarySearchView(
                query: _debouncedQuery,
                onSearchQuran: _openQuranSearch,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LibraryTabTiles(
                    selectedIndex: _selectedTab,
                    counts: [bookmarkCount, noteCount, highlightCount],
                    labels: [
                      AppLocalizations.getMenuText('bookmarks', appLanguage),
                      AppLocalizations.getMenuText('notes', appLanguage),
                      AppLocalizations.getMenuText('highlights', appLanguage),
                    ],
                    onChanged: (index) => setState(() => _selectedTab = index),
                  ),
                  Expanded(
                    child: IndexedStack(
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
}
