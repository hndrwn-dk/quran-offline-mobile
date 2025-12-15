import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class SurahListView extends ConsumerWidget {
  const SurahListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahNamesProvider);

    return surahsAsync.when(
      data: (surahs) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: surahs.length,
          itemBuilder: (context, index) {
            final surah = surahs[index];
            return InkWell(
              onTap: () {
                ref.read(readerSourceProvider.notifier).state = SurahSource(surah.id);
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
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${surah.id}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah.englishName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            surah.arabicName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'UthmanicHafsV22',
                              fontFamilyFallback: const ['UthmanicHafs'],
                              height: 1.4,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ],
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

