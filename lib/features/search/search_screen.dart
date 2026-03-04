import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';

/// Type filter for search results (UI-only; applied to provider list).
const List<String> _typeFilterKeys = ['all', 'surah', 'juz', 'page', 'ayat', 'terjemahan'];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _selectedTypeFilter = 'all';

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
        return results.where((r) => r.type == 'verse' && r.title.startsWith('QS ')).toList();
      case 'terjemahan':
        return results.where((r) => r.type == 'verse' && !r.title.startsWith('QS ')).toList();
      default:
        return results;
    }
  }

  /// Bold-only highlight: first match only; case-insensitive for text, exact for numbers.
  List<TextSpan> buildHighlightedSpans(String text, String query, TextStyle normal, TextStyle highlight) {
    if (query.isEmpty) return [TextSpan(text: text, style: normal)];
    final q = query.trim();
    if (q.isEmpty) return [TextSpan(text: text, style: normal)];
    final isNumeric = int.tryParse(q) != null;
    int start;
    if (isNumeric) {
      start = text.indexOf(q);
    } else {
      start = text.toLowerCase().indexOf(q.toLowerCase());
    }
    if (start == -1) return [TextSpan(text: text, style: normal)];
    final end = start + q.length;
    return [
      if (start > 0) TextSpan(text: text.substring(0, start), style: normal),
      TextSpan(text: text.substring(start, end), style: highlight),
      if (end < text.length) TextSpan(text: text.substring(end), style: normal),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(enhancedSearchResultsProvider);
    final settings = ref.watch(settingsProvider);

    // When user changes the search query, reset type filter to "All" so new results (e.g. terjemahan for "sabar") are visible.
    ref.listen<String>(searchQueryProvider, (prev, next) {
      if (prev != next && _selectedTypeFilter != 'all') {
        setState(() => _selectedTypeFilter = 'all');
      }
    });

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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.filter_alt_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.getSubtitleText('search_subtitle', settings.appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Material(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.getSearchText('search_placeholder', settings.appLanguage),
                          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          ref.read(searchQueryProvider.notifier).state = value;
                        },
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.surface,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              data: (results) {
                if (query.isEmpty) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppLocalizations.getSearchText('search_title', settings.appLanguage),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.getSearchText('search_by_label', settings.appLanguage),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSearchHint(
                            context,
                            Icons.book,
                            AppLocalizations.getMenuText('surah', settings.appLanguage),
                            AppLocalizations.getSearchText('surah_example', settings.appLanguage),
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.format_list_numbered,
                            AppLocalizations.getMenuText('juz', settings.appLanguage),
                            AppLocalizations.getSearchText('juz_example', settings.appLanguage),
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.pages,
                            AppLocalizations.getMenuText('page', settings.appLanguage),
                            AppLocalizations.getSearchText('page_example', settings.appLanguage),
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.numbers,
                            AppLocalizations.getSearchText('verse_label', settings.appLanguage),
                            AppLocalizations.getSearchText('verse_example', settings.appLanguage),
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.translate,
                            AppLocalizations.getSearchText('translation_label', settings.appLanguage),
                            AppLocalizations.getSearchText('translation_example', settings.appLanguage),
                            colorScheme,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered = _filterResults(results, _selectedTypeFilter);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.getSearchText('no_results', settings.appLanguage),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final colorScheme = Theme.of(context).colorScheme;
                final textTheme = Theme.of(context).textTheme;
                final appLanguage = settings.appLanguage;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type filter chips row (pill style, 8px gap)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_typeFilterKeys.length, (i) {
                            final key = _typeFilterKeys[i];
                            final label = key == 'all'
                                ? AppLocalizations.getSettingsText('filter_all', appLanguage)
                                : key == 'ayat'
                                    ? AppLocalizations.getSearchText('verse_label', appLanguage)
                                    : key == 'terjemahan'
                                        ? AppLocalizations.getSearchText('translation_label', appLanguage)
                                        : AppLocalizations.getMenuText(key, appLanguage);
                            final isSelected = _selectedTypeFilter == key;
                            return Padding(
                              padding: EdgeInsets.only(right: i < _typeFilterKeys.length - 1 ? 8 : 0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedTypeFilter = key),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? colorScheme.primary : colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? Colors.transparent : colorScheme.outline.withOpacity(0.12),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    // Result count header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
                      child: Text(
                        '${AppLocalizations.getSearchText('results_heading', appLanguage)} • ${filtered.length}',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final result = filtered[index];
                          IconData icon;
                          Color? iconColor;

                          switch (result.type) {
                            case 'surah':
                              icon = Icons.book;
                              iconColor = Colors.blue;
                              break;
                            case 'juz':
                              icon = Icons.format_list_numbered;
                              iconColor = Colors.green;
                              break;
                            case 'page':
                              icon = Icons.pages;
                              iconColor = Colors.orange;
                              break;
                            default:
                              icon = Icons.text_fields;
                              iconColor = null;
                          }

                          final titleStyle = textTheme.titleMedium ?? const TextStyle();
                          final subtitleStyle = textTheme.bodySmall ?? const TextStyle();
                          final highlightStyle = (query.isEmpty ? titleStyle : titleStyle.copyWith(fontWeight: FontWeight.bold));
                          final subtitleHighlightStyle = (query.isEmpty ? subtitleStyle : subtitleStyle.copyWith(fontWeight: FontWeight.bold));

                          Widget titleWidget = query.isEmpty
                              ? Text(
                                  result.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : RichText(
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: titleStyle.copyWith(color: colorScheme.onSurface),
                                    children: buildHighlightedSpans(
                                      result.title,
                                      query,
                                      titleStyle.copyWith(color: colorScheme.onSurface),
                                      highlightStyle.copyWith(color: colorScheme.onSurface),
                                    ),
                                  ),
                                );
                          Widget? subtitleWidget;
                          if (result.subtitle != null) {
                            subtitleWidget = query.isEmpty
                                ? Text(
                                    result.subtitle!,
                                    style: subtitleStyle,
                                  )
                                : RichText(
                                    text: TextSpan(
                                      style: subtitleStyle.copyWith(color: colorScheme.onSurfaceVariant),
                                      children: buildHighlightedSpans(
                                        result.subtitle!,
                                        query,
                                        subtitleStyle.copyWith(color: colorScheme.onSurfaceVariant),
                                        subtitleHighlightStyle.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                  );
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: iconColor?.withOpacity(0.1),
                                child: Icon(icon, color: iconColor),
                              ),
                              title: titleWidget,
                              subtitle: subtitleWidget,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
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
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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

  Widget _buildSearchHint(
    BuildContext context,
    IconData icon,
    String title,
    String example,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  example,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

