import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/quick_search_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';

class QuickSearchBar extends ConsumerStatefulWidget {
  const QuickSearchBar({super.key});

  @override
  ConsumerState<QuickSearchBar> createState() => QuickSearchBarState();
}

class QuickSearchBarState extends ConsumerState<QuickSearchBar> {

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _textController.text.isEmpty) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        Future.microtask(() => _focusNode.requestFocus());
      } else {
        _textController.clear();
        ref.read(quickSearchQueryProvider.notifier).state = '';
        _focusNode.unfocus();
      }
    });
  }

  void _onQueryChanged(String value) {
    ref.read(quickSearchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _textController.clear();
    ref.read(quickSearchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  void _handleResultTap(QuickSearchResult result) {
    // Clear search
    _textController.clear();
    ref.read(quickSearchQueryProvider.notifier).state = '';
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
    });

    // Navigate based on result type
    if (result.type == 'page' && result.source is PageSource) {
      final pageSource = result.source as PageSource;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MushafPageView(
            initialPage: pageSource.pageNo,
          ),
        ),
      );
    } else {
      // For surah and juz, use ReaderScreen
      ref.read(readerSourceProvider.notifier).state = result.source;
      if (result.source is SurahSource) {
        final surahSource = result.source as SurahSource;
        ref.read(targetAyahProvider.notifier).state = surahSource.targetAyahNo;
      } else {
        ref.read(targetAyahProvider.notifier).state = null;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReaderScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final query = ref.watch(quickSearchQueryProvider);
    final resultsAsync = ref.watch(quickSearchResultsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                    Icon(
                      Icons.search,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        onChanged: _onQueryChanged,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.getSubtitleText('quick_search_hint', settings.appLanguage),
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (query.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _clearSearch,
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (_isExpanded && query.isNotEmpty)
          resultsAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.getSubtitleText('quick_search_no_results', settings.appLanguage),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withOpacity(0.1),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      IconData icon;
                      Color iconColor;
                      
                      switch (result.type) {
                        case 'surah':
                          icon = Icons.menu_book_outlined;
                          iconColor = colorScheme.primary;
                          break;
                        case 'juz':
                          icon = Icons.library_books_outlined;
                          iconColor = colorScheme.secondary;
                          break;
                        case 'page':
                          icon = Icons.auto_stories_outlined;
                          iconColor = colorScheme.tertiary;
                          break;
                        default:
                          icon = Icons.search;
                          iconColor = colorScheme.onSurfaceVariant;
                      }

                      return InkWell(
                        onTap: () => _handleResultTap(result),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  icon,
                                  size: 20,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.title,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (result.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        result.subtitle!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  // Expose method to toggle search from parent
  void toggle() {
    _toggleSearch();
  }
}

