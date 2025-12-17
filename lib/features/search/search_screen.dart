import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(enhancedSearchResultsProvider);

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
                  'Search across the Qur’an',
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
                          hintText: 'Surah, Juz, Page, Verse (2:255), or translation...',
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
                            'Search the Qur\'an',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You can search by:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSearchHint(
                            context,
                            Icons.book,
                            'Surah',
                            'Al-Fatihah, Al-Baqarah, etc.',
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.format_list_numbered,
                            'Juz',
                            'Juz 1, Juz 2, etc.',
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.pages,
                            'Page',
                            'Page 604, Page 1, etc.',
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.numbers,
                            'Verse',
                            '2:255, 3:190, etc.',
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSearchHint(
                            context,
                            Icons.translate,
                            'Translation',
                            'Any word in translation text',
                            colorScheme,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (results.isEmpty) {
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
                          'No results found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
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

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor?.withOpacity(0.1),
                          child: Icon(icon, color: iconColor),
                        ),
                        title: Text(
                          result.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: result.subtitle != null
                            ? Text(
                                result.subtitle!,
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // For page results, navigate to Mushaf mode
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
                            // For surah, juz, and verse results, use ReaderScreen
                            ref.read(readerSourceProvider.notifier).state = result.source;
                            // Set target ayah if source is SurahSource with targetAyahNo
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

