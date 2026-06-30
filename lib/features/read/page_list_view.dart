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
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/read/widgets/read_grouped_surah_card.dart';
import 'package:quran_offline/features/read/widgets/read_surah_list_row.dart';

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
          padding: const EdgeInsets.symmetric(
            horizontal: kAppContentHorizontalInset,
            vertical: 8,
          ),
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _openMushafPage(
                                        context,
                                        ref,
                                        pageNo,
                                      ),
                                      child: Text(
                                        AppLocalizations.getPageText(
                                          pageNo,
                                          settings.appLanguage,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _openMushafPage(
                                      context,
                                      ref,
                                      pageNo,
                                    ),
                                    child: Text(
                                      AppLocalizations.getReadPage(
                                        settings.appLanguage,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ReadGroupedSurahCard(
                                child: Column(
                                  children: [
                                    for (final entry in pageSurahs.surahIds
                                        .asMap()
                                        .entries) ...[
                                      if (entry.key > 0)
                                        const ReadGroupedSurahDivider(),
                                      _PageSurahRow(
                                        surahId: entry.value,
                                        surahs: surahs,
                                        appLanguage: settings.appLanguage,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                AppLocalizations.getPageText(
                                  pageNo,
                                  settings.appLanguage,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ),
                            Container(
                              height: 72,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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

class _PageSurahRow extends StatelessWidget {
  const _PageSurahRow({
    required this.surahId,
    required this.surahs,
    required this.appLanguage,
  });

  final int surahId;
  final List<SurahInfo> surahs;
  final String appLanguage;

  @override
  Widget build(BuildContext context) {
    final surahInfo = surahs.firstWhere(
      (s) => s.id == surahId,
      orElse: () => SurahInfo(
        id: surahId,
        arabicName: '',
        englishName: 'Surah $surahId',
        englishMeaning: '',
      ),
    );
    final meaning = surahInfo.getMeaning(appLanguage);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: ReadSurahListRow(
        surahId: surahInfo.id,
        name: surahInfo.englishName,
        meaning: meaning.isEmpty ? null : meaning,
        trailingDetail: null,
      ),
    );
  }
}
