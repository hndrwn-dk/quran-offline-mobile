import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

class WeeklyReflectionCard extends ConsumerWidget {
  const WeeklyReflectionCard({super.key, this.forHome = false});

  final bool forHome;

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
          padding: forHome
              ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
              : const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Material(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openDetail(context, ref, pick, lang),
              child: Ink(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, forHome ? 10 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 18,
                            color: forHome
                                ? colorScheme.primary
                                : colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.getReflectionCardTitle(
                                sourceKey,
                                lang,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: forHome
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (entry.showsOccasionBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppLocalizations.getReflectionBadge(
                                  entry.badgeKey,
                                  lang,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: _onTint(colorScheme),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.title.forLanguage(lang),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: forHome ? 17 : null,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        refLabel,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: forHome
                                      ? colorScheme.primary
                                      : colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        contextSnippet,
                        maxLines: forHome ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        entry.reflection.forLanguage(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                              fontSize: (Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.fontSize ??
                                      12) -
                                  1,
                            ),
                      ),
                      if (forHome) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                _openDetail(context, ref, pick, lang),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.getHomeReflectionReadAyah(
                                    lang,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}

/// Foreground on the tint fill. Dark primary is too close to the dark tint
/// to read, so dark mode uses the container's own foreground.
Color _onTint(ColorScheme colorScheme) =>
    colorScheme.brightness == Brightness.dark
        ? colorScheme.onPrimaryContainer
        : colorScheme.primary;

void _openDetail(
  BuildContext context,
  WidgetRef ref,
  ReflectionPick pick,
  String lang,
) {
  final entry = pick.entry;
  showExploreDetailSheet(
    context: context,
    ref: ref,
    lang: lang,
    title: entry.title,
    summary: entry.summary,
    sectionNote: entry.reflection,
    sectionHeading: AppLocalizations.getReflectionReflectionHeading(lang),
    ayahRefs: entry.ayahRefs,
    onOpenReader: (ayahRef) {
      openReaderFromAyahRef(ref, ayahRef);
      openReaderScreen(context, ref);
    },
  );
}
