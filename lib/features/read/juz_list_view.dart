import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/read/widgets/read_grouped_surah_card.dart';
import 'package:quran_offline/features/read/widgets/read_surah_list_row.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

class JuzListView extends ConsumerWidget {
  const JuzListView({super.key, this.topWidgets = const []});

  final List<Widget> topWidgets;

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
                final juzNo = index + 1;
                final juzSurahsAsync = ref.watch(juzSurahsProvider(juzNo));

                return surahsAsync.when(
                  data: (surahs) {
                    return juzSurahsAsync.when(
                      data: (juzSurahs) {
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
                                      onTap: () {
                                        final source = JuzSource(juzNo);
                                        ref
                                            .read(readerSourceProvider.notifier)
                                            .state = source;
                                        ref
                                            .read(lastReadProvider.notifier)
                                            .saveLastRead(source);
                                        openReaderScreen(context, ref);
                                      },
                                      child: Text(
                                        AppLocalizations.getJuzTitle(
                                          settings.appLanguage,
                                          juzNo,
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
                                    onTap: () {
                                      final source = JuzSource(juzNo);
                                      ref
                                          .read(readerSourceProvider.notifier)
                                          .state = source;
                                      ref
                                          .read(lastReadProvider.notifier)
                                          .saveLastRead(source);
                                      openReaderScreen(context, ref);
                                    },
                                    child: Text(
                                      AppLocalizations.getReadJuz(
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
                                    for (final entry in juzSurahs.surahIds
                                        .asMap()
                                        .entries) ...[
                                      if (entry.key > 0)
                                        const ReadGroupedSurahDivider(),
                                      _JuzSurahRow(
                                        juzNo: juzNo,
                                        surahId: entry.value,
                                        surahs: surahs,
                                        ayahCount: juzSurahs
                                                .surahAyahCounts[entry.value] ??
                                            0,
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
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 22,
                              width: 120,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 88,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      error: (error, stack) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading Juz $juzNo: $error',
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
              childCount: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class _JuzSurahRow extends ConsumerWidget {
  const _JuzSurahRow({
    required this.juzNo,
    required this.surahId,
    required this.surahs,
    required this.ayahCount,
    required this.appLanguage,
  });

  final int juzNo;
  final int surahId;
  final List<SurahInfo> surahs;
  final int ayahCount;
  final String appLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final source = SurahInJuzSource(juzNo, surahId);
          ref.read(readerSourceProvider.notifier).state = source;
          ref.read(lastReadProvider.notifier).saveLastRead(source);
          openReaderScreen(context, ref);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: ReadSurahListRow(
            surahId: surahInfo.id,
            name: surahInfo.englishName,
            meaning: meaning.isEmpty ? null : meaning,
            trailingDetail: AppLocalizations.formatSurahVerseCount(
              appLanguage,
              ayahCount,
            ),
          ),
        ),
      ),
    );
  }
}
