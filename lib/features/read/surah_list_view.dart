import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/read/widgets/read_grouped_surah_card.dart';
import 'package:quran_offline/features/read/widgets/read_surah_list_row.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

class SurahListView extends ConsumerWidget {
  const SurahListView({super.key, this.topWidgets = const []});

  final List<Widget> topWidgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return surahsAsync.when(
      data: (surahs) {
        return CustomScrollView(
          slivers: [
            for (final widget in topWidgets) SliverToBoxAdapter(child: widget),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: kAppContentHorizontalInset,
                vertical: 8,
              ),
              sliver: SliverList.separated(
                itemCount: surahs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final surah = surahs[index];

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('surah_list_${surah.id}'),
                      onTap: () {
                        final source = SurahSource(surah.id);
                        ref.read(readerSourceProvider.notifier).state = source;
                        ref.read(lastReadProvider.notifier).saveLastRead(source);
                        openReaderScreen(context, ref);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        decoration: ReadGroupedSurahCard.standaloneDecoration(
                          colorScheme,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                          child: FutureBuilder<int>(
                            future: ref
                                .read(databaseProvider)
                                .getAyahCountForSurah(surah.id),
                            builder: (context, snapshot) {
                              final ayahCount = snapshot.data ?? 0;
                              final meaning =
                                  surah.getMeaning(settings.appLanguage);

                              return ReadSurahListRow(
                                surahId: surah.id,
                                name: surah.englishName,
                                meaning:
                                    meaning.isEmpty ? null : meaning,
                                trailingDetail:
                                    AppLocalizations.formatSurahVerseCount(
                                  settings.appLanguage,
                                  ayahCount,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
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
    );
  }
}
