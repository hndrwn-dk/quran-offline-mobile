import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

class WeeklyReflectionCard extends ConsumerWidget {
  const WeeklyReflectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickAsync = ref.watch(reflectionPickProvider);
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return pickAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pick) {
        final entry = pick.entry;
        final refLabel = entry.ayahRefs.length == 1
            ? AppLocalizations.formatDuaAyahRef(
                entry.primaryRef.surah,
                entry.primaryRef.from,
                entry.primaryRef.to,
                lang,
              )
            : AppLocalizations.formatThemeAyahLabel(entry.ayahCount, lang);
        final sourceKey = switch (pick.source) {
          ReflectionPickSource.weekly => 'weekly',
          ReflectionPickSource.calendar => 'calendar',
          ReflectionPickSource.timeOfDay => 'calendar',
        };
        final contextSnippet = entry.summary.forLanguage(lang);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDetail(context, ref, pick, lang),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 18,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.getReflectionCardTitle(
                            sourceKey,
                            lang,
                          ),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.getReflectionBadge(
                            entry.badgeKey,
                            lang,
                          ),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entry.title.forLanguage(lang),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    refLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.getReflectionContextLabel(lang),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contextSnippet,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(
    BuildContext context,
    WidgetRef ref,
    ReflectionPick pick,
    String lang,
  ) {
    final entry = pick.entry;
    showExploreDetailSheet(
      context: context,
      lang: lang,
      title: entry.title,
      summary: entry.summary,
      sectionNote: entry.reflection,
      sectionHeading: AppLocalizations.getReflectionReflectionHeading(lang),
      ayahRefs: entry.ayahRefs,
      onOpenReader: () {
        openReaderFromAyahRefs(ref, entry.ayahRefs);
        openReaderScreen(context, ref);
      },
    );
  }
}
