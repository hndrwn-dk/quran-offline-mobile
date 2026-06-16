import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/home/widgets/home_cta_buttons.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

class LastReadCard extends ConsumerWidget {
  const LastReadCard({super.key, this.forHome = false});

  final bool forHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadProvider);
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final surahsAsync = ref.watch(surahNamesProvider);

    if (lastRead == null) {
      if (!forHome) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _HomeLastReadShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeContinuePill(
                label: AppLocalizations.getHomeStartPill(appLanguage),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.getHomeStartReadingTitle(appLanguage),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.getHomeStartReadingBody(appLanguage),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: HomeCircleArrowButton(
                  onPressed: () {
                    ref.read(currentTabProvider.notifier).state = AppTab.read;
                  },
                  tooltip: AppLocalizations.getHomeStartButton(appLanguage),
                  semanticsLabel: AppLocalizations.getHomeStartReadingTitle(appLanguage),
                  onTintedCard: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progressAsync = forHome ? ref.watch(lastReadProgressProvider) : null;

    return surahsAsync.when(
      data: (surahs) {
        String title;
        String subtitle;
        String homeScopeKey;
        IconData icon;
        VoidCallback? onTap;
        VoidCallback? onClear;

        switch (lastRead.type) {
          case 'surah':
            final surah = surahs.firstWhere(
              (s) => s.id == lastRead.id,
              orElse: () => surahs[0],
            );
            title = surah.englishName;
            subtitle = lastRead.ayahNo != null
                ? AppLocalizations.formatMiniPlayerTitle(
                    language: appLanguage,
                    surahLabel: surah.englishName,
                    ayahNo: lastRead.ayahNo,
                    isBismillah: false,
                  )
                : surah.englishName;
            homeScopeKey = 'surah';
            icon = Icons.menu_book_outlined;
            onTap = () {
              final source = SurahSource(lastRead.id, targetAyahNo: lastRead.ayahNo);
              ref.read(readerSourceProvider.notifier).state = source;
              ref.read(targetAyahProvider.notifier).state = lastRead.ayahNo;
              openReaderScreen(context, ref);
            };
            break;
          case 'juz':
            title = 'Juz ${lastRead.id}';
            homeScopeKey = 'juz';
            if (lastRead.ayahNo != null && lastRead.surahId != null) {
              final surah = surahs.firstWhere(
                (s) => s.id == lastRead.surahId,
                orElse: () => surahs[0],
              );
              subtitle = AppLocalizations.formatMiniPlayerTitle(
                language: appLanguage,
                surahLabel: surah.englishName,
                ayahNo: lastRead.ayahNo,
                isBismillah: false,
              );
            } else {
              subtitle = lastRead.ayahNo != null
                  ? '${AppLocalizations.getMenuText('juz', appLanguage)} ${lastRead.id}:${lastRead.ayahNo}'
                  : AppLocalizations.getMenuText('juz', appLanguage);
            }
            icon = Icons.library_books_outlined;
            onTap = () {
              final source = JuzSource(lastRead.id);
              ref.read(readerSourceProvider.notifier).state = source;
              if (lastRead.ayahNo != null) {
                ref.read(targetAyahProvider.notifier).state = lastRead.ayahNo;
              }
              openReaderScreen(context, ref);
            };
            break;
          case 'page':
            title = AppLocalizations.getPageText(lastRead.id, appLanguage);
            homeScopeKey = 'page';
            if (lastRead.ayahNo != null && lastRead.surahId != null) {
              final surah = surahs.firstWhere(
                (s) => s.id == lastRead.surahId,
                orElse: () => surahs[0],
              );
              subtitle = AppLocalizations.formatMiniPlayerTitle(
                language: appLanguage,
                surahLabel: surah.englishName,
                ayahNo: lastRead.ayahNo,
                isBismillah: false,
              );
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

        if (forHome) {
          final progress = progressAsync?.valueOrNull;
          final homeSubtitle = AppLocalizations.formatHomeLastReadSubtitle(
            language: appLanguage,
            ayahNo: lastRead.ayahNo,
            scopeKey: homeScopeKey,
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _HomeLastReadShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HomeContinuePill(
                              label: AppLocalizations.getHomeContinuePill(appLanguage),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              homeSubtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(width: 12),
                        _HomeProgressRing(
                          percent: progress.percent,
                          fraction: progress.fraction,
                        ),
                      ],
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.getHomeProgressScopeLabel(
                              progress.scope,
                              appLanguage,
                            ),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        Text(
                          '${progress.percent}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.fraction.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: HomeCircleArrowButton(
                      onPressed: onTap,
                      tooltip: AppLocalizations.getHomeContinueButton(appLanguage),
                      semanticsLabel: AppLocalizations.getHomeContinueCta(appLanguage),
                      onTintedCard: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

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
                    tooltip: AppLocalizations.getActionTooltip('clear', appLanguage),
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

class _HomeLastReadShell extends StatelessWidget {
  const _HomeLastReadShell({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primaryContainer.withValues(alpha: 0.42),
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
                ]
              : [
                  const Color(0xFFF4F7F0),
                  const Color(0xFFE8F0E4),
                  Color.lerp(
                    const Color(0xFFDCE8D8),
                    colorScheme.primary,
                    0.12,
                  )!,
                ],
          stops: isDark ? null : const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: child,
      ),
    );
  }
}

class _HomeContinuePill extends StatelessWidget {
  const _HomeContinuePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

class _HomeProgressRing extends StatelessWidget {
  const _HomeProgressRing({
    required this.percent,
    required this.fraction,
  });

  final int percent;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    const outerSize = 44.0;
    const innerSize = 34.0;

    final ringTrack = colorScheme.primary.withValues(
      alpha: isDark ? 0.22 : 0.16,
    );
    final ringProgress = colorScheme.primary.withValues(alpha: isDark ? 0.78 : 0.58);
    final fillTop = isDark
        ? colorScheme.surface.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.9);
    final fillBottom = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : const Color(0xFFF0F5EC).withValues(alpha: 0.85);

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: outerSize,
            height: outerSize,
            child: CircularProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
              backgroundColor: ringTrack,
              color: ringProgress,
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [fillTop, fillBottom],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
