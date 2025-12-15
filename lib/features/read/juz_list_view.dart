import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class JuzListView extends ConsumerWidget {
  const JuzListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahNamesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNo = index + 1;
        final juzSurahsAsync = ref.watch(juzSurahsProvider(juzNo));

        return surahsAsync.when(
          data: (surahs) {
            return juzSurahsAsync.when(
              data: (juzSurahs) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Juz Header with "Read Juz" link
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                ref.read(readerSourceProvider.notifier).state = JuzSource(juzNo);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReaderScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Juz $juzNo',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ref.read(readerSourceProvider.notifier).state = JuzSource(juzNo);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReaderScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Read Juz',
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
                    // Surah List
                    ...juzSurahs.surahIds.map((surahId) {
                      final surahInfo = surahs.firstWhere(
                        (s) => s.id == surahId,
                        orElse: () => SurahInfo(
                          id: surahId,
                          arabicName: '',
                          englishName: 'Surah $surahId',
                          englishMeaning: '',
                        ),
                      );
                      final ayahCount = juzSurahs.surahAyahCounts[surahId] ?? 0;

                      return InkWell(
                        onTap: () {
                          ref.read(readerSourceProvider.notifier).state = SurahSource(surahId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReaderScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Diamond shape with surah number
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${surahInfo.id}',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                    if (surahInfo.englishMeaning.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        surahInfo.englishMeaning,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Arabic name and ayah count
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      surahInfo.arabicName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'UthmanicHafsV22',
                                        fontFamilyFallback: const ['UthmanicHafs'],
                                        color: colorScheme.onSurface,
                                        height: 1.4,
                                      ),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$ayahCount Ayahs',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                  ],
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }
}

