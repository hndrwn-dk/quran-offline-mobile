import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class SurahListView extends ConsumerWidget {
  const SurahListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return surahsAsync.when(
      data: (surahs) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: surahs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final surah = surahs[index];

            return InkWell(
              onTap: () {
                final source = SurahSource(surah.id);
                ref.read(readerSourceProvider.notifier).state = source;
                // Save last read (without ayahNo, will be updated when user scrolls)
                ref.read(lastReadProvider.notifier).saveLastRead(source);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReaderScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: FutureBuilder<int>(
                  future: ref.read(databaseProvider).getAyahCountForSurah(surah.id),
                  builder: (context, snapshot) {
                    final ayahCount = snapshot.data ?? 0;
                    
                    return Row(
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
                            '${surah.id}',
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
                                surah.englishName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final meaning = surah.getMeaning(settings.appLanguage);
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
                                surah.arabicName,
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
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

