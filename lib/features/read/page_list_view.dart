import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/page_surahs_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';

class PageListView extends ConsumerWidget {
  const PageListView({super.key, this.topWidgets = const []});

  final List<Widget> topWidgets;

  Future<void> _openMushafPage(
    BuildContext context,
    WidgetRef ref,
    int pageNo,
  ) async {
    final source = PageSource(pageNo);
    ref.read(lastReadProvider.notifier).saveLastRead(source);
    MushafWarmup.beginSession(priorityPage: pageNo);
    await MushafLayout.prewarmPage(context, pageNo);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MushafPageView(initialPage: pageNo),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        for (final widget in topWidgets) SliverToBoxAdapter(child: widget),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
        final pageNo = index + 1;
        final pageSurahsAsync = ref.watch(pageSurahsProvider(pageNo));

        return surahsAsync.when(
          data: (surahs) {
            return pageSurahsAsync.when(
              data: (pageSurahs) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Header with "Read Page" link
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _openMushafPage(context, ref, pageNo),
                              child: Text(
                                AppLocalizations.getPageText(pageNo, settings.appLanguage),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _openMushafPage(context, ref, pageNo),
                            child: Text(
                              AppLocalizations.getReadPage(settings.appLanguage),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Surah List Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ...pageSurahs.surahIds.asMap().entries.map((entry) {
                              final index = entry.key;
                              final surahId = entry.value;
                              final surahInfo = surahs.firstWhere(
                                (s) => s.id == surahId,
                                orElse: () => SurahInfo(
                                  id: surahId,
                                  arabicName: '',
                                  englishName: 'Surah $surahId',
                                  englishMeaning: '',
                                ),
                              );
                              final isLast = index == pageSurahs.surahIds.length - 1;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                            color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Surah number
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${surahInfo.id}',
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
                                          Text(
                                            surahInfo.englishName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
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
                                    // Arabic name
                                    SurahNameListGlyph(surahId: surahInfo.id),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        AppLocalizations.getPageText(pageNo, settings.appLanguage),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.formatPageLoadError(
                    settings.appLanguage,
                    pageNo,
                    error,
                  ),
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
              },
              childCount: 604,
            ),
          ),
        ),
      ],
    );
  }
}

