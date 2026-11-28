import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/quick_search_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
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
          AppSearchFieldInset(
            child: AppSearchField(
              controller: _textController,
              focusNode: _focusNode,
              hintText: AppLocalizations.getSubtitleText(
                'quick_search_hint',
                settings.appLanguage,
              ),
              onChanged: _onQueryChanged,
              onClear: _clearSearch,
            ),
          ),
        if (_isExpanded && query.isNotEmpty)
          resultsAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                  kAppContentHorizontalInset,
                  0,
                  kAppContentHorizontalInset,
                  8,
                ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.card,
                      borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.fromLTRB(
                  kAppContentHorizontalInset,
                  0,
                  kAppContentHorizontalInset,
                  8,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Material(
                    color: colorScheme.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: results.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.hairline,
                        indent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        IconData icon;

                        switch (result.type) {
                          case 'surah':
                            icon = Icons.menu_book_outlined;
                            break;
                          case 'juz':
                            icon = Icons.library_books_outlined;
                            break;
                          case 'page':
                            icon = Icons.auto_stories_outlined;
                            break;
                          default:
                            icon = Icons.search;
                        }

                        return InkWell(
                          onTap: () => _handleResultTap(result),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                AppBadge(icon: icon, size: 36),
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
                                      if (result.type == 'surah' &&
                                          result.source is SurahSource) ...[
                                        const SizedBox(height: 2),
                                        SurahNameSearchGlyph(
                                          surahId: (result.source as SurahSource).surahId,
                                        ),
                                      ] else if (result.subtitle != null) ...[
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
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(
                kAppContentHorizontalInset,
                0,
                kAppContentHorizontalInset,
                8,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.circular(20),
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

