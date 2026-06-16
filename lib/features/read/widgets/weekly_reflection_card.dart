import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/home/widgets/home_cta_buttons.dart';
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
          padding: EdgeInsets.fromLTRB(16, 8, 16, forHome ? 8 : 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDetail(context, ref, pick, lang),
              borderRadius: BorderRadius.circular(forHome ? 20 : 16),
              child: Ink(
                decoration: forHome
                    ? _homeReflectionDecoration(colorScheme)
                    : BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    forHome ? 14 : 16,
                    forHome ? 16 : 16,
                    forHome ? 14 : 16,
                    forHome ? 16 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 18,
                            color: forHome ? colorScheme.primary : colorScheme.secondary,
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
                              color: forHome
                                  ? (colorScheme.brightness == Brightness.dark
                                      ? colorScheme.surface.withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.58))
                                  : colorScheme.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: forHome
                                  ? Border.all(
                                      color: colorScheme.primary.withValues(
                                        alpha: colorScheme.brightness == Brightness.dark
                                            ? 0.28
                                            : 0.16,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Text(
                              AppLocalizations.getReflectionBadge(
                                entry.badgeKey,
                                lang,
                              ),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: forHome ? colorScheme.primary : colorScheme.secondary,
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
                              color: forHome ? colorScheme.primary : colorScheme.secondary,
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
                        maxLines: forHome ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                      if (forHome) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: HomeCircleArrowButton(
                            onPressed: () => _openDetail(context, ref, pick, lang),
                            tooltip: AppLocalizations.getHomeReflectionCta(lang),
                            semanticsLabel: AppLocalizations.getHomeReflectionCta(lang),
                            onTintedCard: true,
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

BoxDecoration _homeReflectionDecoration(ColorScheme colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
    ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              colorScheme.secondaryContainer.withValues(alpha: 0.38),
              colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            ]
          : [
              const Color(0xFFF7F4EC),
              const Color(0xFFEFE9DF),
              Color.lerp(
                const Color(0xFFE6DFD3),
                colorScheme.primary,
                0.08,
              )!,
            ],
      stops: isDark ? null : const [0.0, 0.52, 1.0],
    ),
    boxShadow: [
      BoxShadow(
        color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.06),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
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
    ref: ref,
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
