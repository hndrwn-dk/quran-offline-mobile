import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class JuzListView extends ConsumerWidget {
  const JuzListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
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
                                final source = JuzSource(juzNo);
                                ref.read(readerSourceProvider.notifier).state = source;
                                // Save last read
                                ref.read(lastReadProvider.notifier).saveLastRead(source);
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
                              final source = JuzSource(juzNo);
                              ref.read(readerSourceProvider.notifier).state = source;
                              // Save last read
                              ref.read(lastReadProvider.notifier).saveLastRead(source);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReaderScreen(),
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.getReadJuz(settings.appLanguage),
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
                              color: colorScheme.shadow.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ...juzSurahs.surahIds.asMap().entries.map((entry) {
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
                              final ayahCount = juzSurahs.surahAyahCounts[surahId] ?? 0;
                              final isLast = index == juzSurahs.surahIds.length - 1;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                            color: colorScheme.outlineVariant.withOpacity(0.1),
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
                                    // Arabic name and ayah count
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Text(
                                            surahInfo.arabicName,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
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

