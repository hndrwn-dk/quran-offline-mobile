import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class LastReadCard extends ConsumerWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadProvider);
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final surahsAsync = ref.watch(surahNamesProvider);

    if (lastRead == null) {
      return const SizedBox.shrink();
    }

    return surahsAsync.when(
      data: (surahs) {
        String title;
        String subtitle;
        IconData icon;
        VoidCallback? onTap;
        VoidCallback? onClear;

        switch (lastRead.type) {
          case 'surah':
            final surah = surahs.firstWhere(
              (s) => s.id == lastRead.id,
              orElse: () => surahs[0],
            );
            title = '${surah.englishName}';
            subtitle = lastRead.ayahNo != null
                ? '${AppLocalizations.getMenuText('surah', appLanguage)} ${lastRead.id}:${lastRead.ayahNo}'
                : '${AppLocalizations.getMenuText('surah', appLanguage)} ${lastRead.id}';
            icon = Icons.menu_book_outlined;
            onTap = () {
              final source = SurahSource(lastRead.id, targetAyahNo: lastRead.ayahNo);
              ref.read(readerSourceProvider.notifier).state = source;
              ref.read(targetAyahProvider.notifier).state = lastRead.ayahNo;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReaderScreen(),
                ),
              );
            };
            break;
          case 'juz':
            title = 'Juz ${lastRead.id}';
            subtitle = lastRead.ayahNo != null
                ? '${AppLocalizations.getMenuText('juz', appLanguage)} ${lastRead.id}:${lastRead.ayahNo}'
                : AppLocalizations.getMenuText('juz', appLanguage);
            icon = Icons.library_books_outlined;
            onTap = () {
              final source = JuzSource(lastRead.id);
              ref.read(readerSourceProvider.notifier).state = source;
              if (lastRead.ayahNo != null) {
                ref.read(targetAyahProvider.notifier).state = lastRead.ayahNo;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReaderScreen(),
                ),
              );
            };
            break;
          case 'page':
            title = AppLocalizations.getPageText(lastRead.id, appLanguage);
            if (lastRead.ayahNo != null && lastRead.surahId != null) {
              final surah = surahs.firstWhere(
                (s) => s.id == lastRead.surahId,
                orElse: () => surahs[0],
              );
              subtitle = '${surah.englishName} ${lastRead.surahId}:${lastRead.ayahNo}';
            } else {
              subtitle = AppLocalizations.getMenuText('mushaf', appLanguage);
            }
            icon = Icons.auto_stories_outlined;
            onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MushafPageView(
                    initialPage: lastRead.id,
                    targetSurahId: lastRead.surahId,
                    targetAyahNo: lastRead.ayahNo,
                  ),
                ),
              );
            };
            break;
          default:
            return const SizedBox.shrink();
        }

        onClear = () {
          ref.read(lastReadProvider.notifier).clearLastRead();
        };

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.getLastRead(appLanguage),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: colorScheme.onSurfaceVariant,
                    onPressed: onClear,
                    tooltip: 'Clear',
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

