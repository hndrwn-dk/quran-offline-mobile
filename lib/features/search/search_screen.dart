import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart'
    show SearchResult, SearchVerseMatchKind, enhancedSearchResultsProvider;
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
import 'package:quran_offline/core/widgets/floating_nav_bar.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/search/ai_search_query_kind.dart';
import 'package:quran_offline/features/search/widgets/search_result_list.dart';
import 'package:quran_offline/features/search/widgets/tanya_search_results.dart';

/// Type filter for search results (UI-only; applied to provider list).
const List<String> _typeFilterKeys = [
  'all',
  'surah',
  'juz',
  'page',
  'ayat',
  'terjemahan'
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _selectedTypeFilter = 'all';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _applySampleQuery(String sample) {
    _searchController.text = sample;
    _searchController.selection =
        TextSelection.collapsed(offset: sample.length);
    ref.read(searchQueryProvider.notifier).state = sample;
    _searchFocusNode.requestFocus();
  }

  /// Filter provider results by selected type. Ayat = verse with "QS " title; Terjemahan = verse without.
  List<SearchResult> _filterResults(List<SearchResult> results, String filter) {
    if (filter == 'all') return results;
    switch (filter) {
      case 'surah':
        return results.where((r) => r.type == 'surah').toList();
      case 'juz':
        return results.where((r) => r.type == 'juz').toList();
      case 'page':
        return results.where((r) => r.type == 'page').toList();
      case 'ayat':
        return results
            .where(
              (r) =>
                  r.type == 'verse' &&
                  (r.verseMatchKind == SearchVerseMatchKind.reference ||
                      r.verseMatchKind == SearchVerseMatchKind.arabic),
            )
            .toList();
      case 'terjemahan':
        return results
            .where(
              (r) =>
                  r.type == 'verse' &&
                  r.verseMatchKind == SearchVerseMatchKind.translation,
            )
            .toList();
      default:
        return results;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(enhancedSearchResultsProvider);
    final settings = ref.watch(settingsProvider);
    final aiEnabled = ref.watch(aiSearchEnabledProvider);
    final tanyaAsync = aiEnabled
        ? ref.watch(aiSearchResultsProvider)
        : const AsyncValue<AiSearchResults>.data(AiSearchResults.empty);
    final tanyaCardBuilder = ref.watch(tanyaCardBuilderProvider);

    // When user changes the search query, reset type filter to "All" so new results (e.g. terjemahan for "sabar") are visible.
    ref.listen<int>(searchFocusRequestProvider, (_, __) {
      _searchFocusNode.requestFocus();
    });
    ref.listen<String>(searchQueryProvider, (prev, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
        _searchController.selection = TextSelection.collapsed(
          offset: next.length,
        );
      }
      if (prev != next && _selectedTypeFilter != 'all') {
        setState(() => _selectedTypeFilter = 'all');
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: HomeBackdrop.topTint(Theme.of(context).colorScheme),
      appBar: AppLargeTitleBar(
        title: aiEnabled
            ? AppLocalizations.getAiSearchHeading(settings.appLanguage)
            : AppLocalizations.getMenuText('search', settings.appLanguage),
        subtitle: aiEnabled
            ? AppLocalizations.getAiSearchScreenSubtitle(settings.appLanguage)
            : AppLocalizations.getSubtitleText(
                'search_subtitle',
                settings.appLanguage,
              ),
      ),
      body: HomeBackdrop(
        child: FloatingNavBarInset(
          child: Column(
            children: [
              AppSearchFieldInset(
                child: AppSearchField(
                  textFieldKey: const Key('search_field'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: aiEnabled
                      ? AppLocalizations.getAiSearchPlaceholder(
                          settings.appLanguage)
                      : AppLocalizations.getSearchText(
                          'search_placeholder',
                          settings.appLanguage,
                        ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              Expanded(
                child: resultsAsync.when(
                  data: (results) {
                    if (query.isEmpty) {
                      final colorScheme = Theme.of(context).colorScheme;
                      final appLanguage = settings.appLanguage;
                      if (aiEnabled) {
                        return _AiSearchLanding(
                          language: appLanguage,
                          examples: AppLocalizations.getAiSearchExampleQueries(
                            appLanguage,
                          ),
                          onExampleTap: _applySampleQuery,
                        );
                      }
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSectionLabel(
                              AppLocalizations.getSearchText(
                                'search_by_label',
                                appLanguage,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AppGroupedCard(
                              dividerIndent: 60,
                              children: [
                            _buildSearchHint(
                              context,
                              Icons.book,
                              AppLocalizations.getMenuText(
                                'surah',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchText(
                                'surah_example',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchSampleQuery(
                                'surah',
                                settings.appLanguage,
                              ),
                              colorScheme,
                            ),
                            _buildSearchHint(
                              context,
                              Icons.format_list_numbered,
                              AppLocalizations.getMenuText(
                                'juz',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchText(
                                'juz_example',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchSampleQuery(
                                'juz',
                                settings.appLanguage,
                              ),
                              colorScheme,
                            ),
                            _buildSearchHint(
                              context,
                              Icons.pages,
                              AppLocalizations.getMenuText(
                                'page',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchText(
                                'page_example',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchSampleQuery(
                                'page',
                                settings.appLanguage,
                              ),
                              colorScheme,
                            ),
                            _buildSearchHint(
                              context,
                              Icons.numbers,
                              AppLocalizations.getSearchText(
                                'verse_label',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchText(
                                'verse_example',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchSampleQuery(
                                'ayat',
                                settings.appLanguage,
                              ),
                              colorScheme,
                            ),
                            _buildSearchHint(
                              context,
                              Icons.translate,
                              AppLocalizations.getSearchText(
                                'translation_label',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchText(
                                'translation_example',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchSampleQuery(
                                'terjemahan',
                                settings.appLanguage,
                              ),
                              colorScheme,
                            ),
                            _buildSearchHint(
                              context,
                              Icons.language,
                              AppLocalizations.getSearchText(
                                'arabic_label',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchText(
                                'arabic_example',
                                settings.appLanguage,
                              ),
                              AppLocalizations.getSearchSampleQuery(
                                'arabic',
                                settings.appLanguage,
                              ),
                              colorScheme,
                            ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    final colorScheme = Theme.of(context).colorScheme;
                    final textTheme = Theme.of(context).textTheme;
                    final appLanguage = settings.appLanguage;
                    final translations = translationSearchResults(results);
                    final translationCount = translations.length;
                    final tanyaGroups = tanyaAsync.asData?.value.groups ??
                        const <AiSearchTypeGroup>[];

                    if (aiEnabled) {
                      final kind = detectAiSearchQueryKind(query, results);
                      if (kind == AiSearchQueryKind.direct) {
                        final direct = pickDirectSearchResult(results);
                        if (direct != null) {
                          return _buildClassicGroup(
                            context,
                            heading: AppLocalizations.getAiSearchDirectGroup(
                              appLanguage,
                            ),
                            headingKey: const Key('ai_search_group_direct'),
                            results: [direct],
                            query: query,
                          );
                        }
                      } else if (kind == AiSearchQueryKind.arabic) {
                        return _buildClassicGroup(
                          context,
                          heading: AppLocalizations.getAiSearchArabicGroup(
                            appLanguage,
                          ),
                          headingKey: const Key('ai_search_group_arabic'),
                          results: arabicSearchResults(results),
                          query: query,
                        );
                      }
                      return TanyaSearchResults(
                        groups: tanyaGroups,
                        lang: appLanguage,
                        translationCount: translationCount,
                        cardBuilder: tanyaCardBuilder,
                        loading: tanyaAsync.isLoading,
                        onJumpToTranslation: () {
                          _openTranslationResults(translations, query);
                        },
                      );
                    }

                    final filtered =
                        _filterResults(results, _selectedTypeFilter);

                    if (filtered.isEmpty) {
                      final filterHidesMatches =
                          results.isNotEmpty && _selectedTypeFilter != 'all';
                      final title = AppLocalizations.getSearchText(
                        'no_results',
                        appLanguage,
                      );
                      final subtitle = filterHidesMatches
                          ? AppLocalizations.getSearchNoResultsForFilter(
                              appLanguage,
                              _selectedTypeFilter,
                              tanyaEnabled: aiEnabled,
                            )
                          : AppLocalizations.getSearchText(
                              'search_by_label',
                              appLanguage,
                            );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTypeFilterChips(
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            appLanguage: appLanguage,
                            aiEnabled: aiEnabled,
                          ),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 24,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 56,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.35),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (query.trim().isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.card,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          query.trim(),
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Text(
                                      subtitle,
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                    ),
                                    if (filterHidesMatches) ...[
                                      const SizedBox(height: 20),
                                      FilledButton.tonal(
                                        key:
                                            const Key('search_show_all_filter'),
                                        onPressed: () => setState(
                                          () => _selectedTypeFilter = 'all',
                                        ),
                                        child: Text(
                                          aiEnabled
                                              ? AppLocalizations
                                                  .getAiSearchHeading(
                                                  appLanguage,
                                                )
                                              : AppLocalizations.getSearchText(
                                                  'search_show_all_filter',
                                                  appLanguage,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTypeFilterChips(
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          appLanguage: appLanguage,
                          aiEnabled: aiEnabled,
                        ),
                        if (filtered.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: AppSectionLabel(
                              '${AppLocalizations.getSearchText('results_heading', appLanguage)} • ${filtered.length}',
                            ),
                          ),
                        Expanded(
                          child: SearchResultList(
                            results: filtered,
                            query: query,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTranslationResults(List<SearchResult> translations, String query) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TranslationResultsScreen(
          results: translations,
          query: query,
        ),
      ),
    );
  }

  Widget _buildClassicGroup(
    BuildContext context, {
    required String heading,
    required Key headingKey,
    required List<SearchResult> results,
    required String query,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSectionLabel(heading, key: headingKey),
        ),
        Expanded(
          child: SearchResultList(results: results, query: query),
        ),
      ],
    );
  }

  Widget _buildTypeFilterChips({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String appLanguage,
    required bool aiEnabled,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_typeFilterKeys.length, (i) {
            final key = _typeFilterKeys[i];
            final label = key == 'all'
                ? (aiEnabled
                    ? AppLocalizations.getAiSearchHeading(appLanguage)
                    : AppLocalizations.getSettingsText(
                        'filter_all', appLanguage))
                : key == 'ayat'
                    ? AppLocalizations.getSearchText('verse_label', appLanguage)
                    : key == 'terjemahan'
                        ? AppLocalizations.getSearchText(
                            'translation_label',
                            appLanguage,
                          )
                        : AppLocalizations.getMenuText(key, appLanguage);
            final isSelected = _selectedTypeFilter == key;
            return Padding(
              padding: EdgeInsets.only(
                right: i < _typeFilterKeys.length - 1 ? 8 : 0,
              ),
              child: Material(
                key: Key('search_filter_$key'),
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedTypeFilter = key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? colorScheme.primary : colorScheme.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSearchHint(
    BuildContext context,
    IconData icon,
    String title,
    String example,
    String sampleQuery,
    ColorScheme colorScheme, {
    Key? key,
    bool applyQuery = true,
  }) {
    return _SearchHintRow(
      key: key,
      icon: icon,
      title: title,
      caption: example,
      onTap: applyQuery
          ? () => _applySampleQuery(sampleQuery)
          : () => _searchFocusNode.requestFocus(),
    );
  }
}

/// One row of a grouped "how to type" card: icon badge, sample, caption.
class _SearchHintRow extends StatelessWidget {
  const _SearchHintRow({
    super.key,
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              AppBadge(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSearchLanding extends StatelessWidget {
  const _AiSearchLanding({
    required this.language,
    required this.examples,
    required this.onExampleTap,
  });

  final String language;
  final List<String> examples;
  final ValueChanged<String> onExampleTap;

  static const _typeHintIcons = <IconData>[
    Icons.numbers,
    Icons.format_list_numbered,
    Icons.pages,
  ];

  @override
  Widget build(BuildContext context) {
    final typeHints = AppLocalizations.getAiSearchTypeHints(language);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionLabel(
                  AppLocalizations.getAiSearchTryLabel(language),
                  key: const Key('tanya_try_label'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  key: const Key('tanya_example_row'),
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < examples.length; i++)
                      _SearchExampleChip(
                        key: Key('tanya_example_$i'),
                        label: examples[i],
                        onPressed: () => onExampleTap(examples[i]),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                AppSectionLabel(
                  AppLocalizations.getAiSearchTypeHintLabel(language),
                  key: const Key('tanya_type_hint_label'),
                ),
                const SizedBox(height: 10),
                AppGroupedCard(
                  dividerIndent: 60,
                  children: [
                    for (var i = 0; i < typeHints.length; i++)
                      _SearchHintRow(
                        key: Key('tanya_type_hint_$i'),
                        icon: _typeHintIcons[i],
                        title: typeHints[i].sample,
                        caption: typeHints[i].caption,
                        onTap: () => onExampleTap(typeHints[i].query),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchExampleChip extends StatelessWidget {
  const _SearchExampleChip({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxChipWidth = MediaQuery.sizeOf(context).width - 32;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
