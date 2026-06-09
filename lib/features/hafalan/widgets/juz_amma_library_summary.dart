import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/juz_amma_hafalan.dart';
import 'package:quran_offline/core/providers/juz_amma_hafalan_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/hafalan/juz_amma_screen.dart';

/// Opsi D2: zona program hafalan (bisa ciut) di atas koleksi bacaan.
class JuzAmmaLibrarySummary extends ConsumerWidget {
  const JuzAmmaLibrarySummary({super.key});

  void _openProgram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const JuzAmmaScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final progressAsync = ref.watch(juzAmmaProgressSummaryProvider);
    final collapsed = ref.watch(libraryJuzAmmaCollapsedProvider);

    return progressAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (p) {
        final summary = _buildSummaryData(ref, lang, p);
        if (summary == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.getLibraryProgramSectionTitle(lang),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
              const SizedBox(height: 6),
              if (collapsed)
                _CollapsedStrip(
                  lang: lang,
                  summary: summary,
                  onOpen: () => _openProgram(context),
                  onExpand: () => ref
                      .read(libraryJuzAmmaCollapsedProvider.notifier)
                      .setCollapsed(false),
                )
              else
                _ExpandedCard(
                  lang: lang,
                  summary: summary,
                  onOpen: () => _openProgram(context),
                  onCollapse: () => ref
                      .read(libraryJuzAmmaCollapsedProvider.notifier)
                      .setCollapsed(true),
                ),
            ],
          ),
        );
      },
    );
  }

  _LibrarySummaryData? _buildSummaryData(
    WidgetRef ref,
    String lang,
    JuzAmmaProgressSummary p,
  ) {
    final taskAsync = ref.watch(juzAmmaTodayTaskProvider);
    final queueAsync = ref.watch(fridaySetoranQueueProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final isFriday = DateTime.now().weekday == DateTime.friday;
    final pct = (p.ayahFraction * 100).round();
    final setoranDone = queueAsync.maybeWhen(
      data: (q) => q.where((e) => e.isDone).length,
      orElse: () => 0,
    );
    final setoranTotal = queueAsync.maybeWhen(
      data: (q) => q.length,
      orElse: () => 0,
    );

    final weekday = !isFriday
        ? _buildWeekdayLines(taskAsync, surahsAsync, lang)
        : null;
    final todayLine = weekday?.todayLine;
    final fridayLine = isFriday
        ? AppLocalizations.getJuzAmmaLibraryFridaySetoranLine(
            lang,
            setoranDone,
            setoranTotal,
          )
        : null;

    final stripDetail = isFriday
        ? AppLocalizations.getJuzAmmaLibraryFridaySetoranShort(
            lang,
            setoranDone,
            setoranTotal,
          )
        : (weekday?.stripDetail ?? '${p.memorizedAyahs}/${p.totalAyahs}');

    return _LibrarySummaryData(
      percent: pct,
      memorizedAyahs: p.memorizedAyahs,
      totalAyahs: p.totalAyahs,
      todayLine: todayLine,
      fridayLine: fridayLine,
      stripDetail: stripDetail,
    );
  }

  _WeekdayLines? _buildWeekdayLines(
    AsyncValue<HafalanDayTask> taskAsync,
    AsyncValue<List<SurahInfo>> surahsAsync,
    String lang,
  ) {
    return taskAsync.maybeWhen(
      data: (task) {
        switch (task.kind) {
          case HafalanDayKind.newMemorization:
            final unit = task.unit;
            if (unit == null) return null;
            final surahs = surahsAsync.valueOrNull;
            if (surahs == null) return null;
            final surah = surahs.firstWhere(
              (s) => s.id == unit.surah,
              orElse: () => surahs.first,
            );
            final unitLabel = AppLocalizations.formatJuzAmmaUnitShort(
              lang,
              surah.englishName,
              unit.sort,
            );
            return _WeekdayLines(
              todayLine:
                  AppLocalizations.getJuzAmmaLibraryTodayLine(lang, unitLabel),
              stripDetail: unitLabel,
            );
          case HafalanDayKind.tahsin:
            final tahsin = AppLocalizations.getJuzAmmaTodayTahsin(
              lang,
              task.tahsinDay,
              task.tahsinTotal,
            );
            return _WeekdayLines(
              todayLine: AppLocalizations.getJuzAmmaLibraryTodayLine(
                lang,
                tahsin,
              ),
              stripDetail: tahsin,
            );
          default:
            return null;
        }
      },
      orElse: () => null,
    );
  }
}

class _WeekdayLines {
  const _WeekdayLines({required this.todayLine, required this.stripDetail});

  final String todayLine;
  final String stripDetail;
}

class _LibrarySummaryData {
  const _LibrarySummaryData({
    required this.percent,
    required this.memorizedAyahs,
    required this.totalAyahs,
    required this.stripDetail,
    this.todayLine,
    this.fridayLine,
  });

  final int percent;
  final int memorizedAyahs;
  final int totalAyahs;
  final String stripDetail;
  final String? todayLine;
  final String? fridayLine;
}

class _ExpandedCard extends StatelessWidget {
  const _ExpandedCard({
    required this.lang,
    required this.summary,
    required this.onOpen,
    required this.onCollapse,
  });

  final String lang;
  final _LibrarySummaryData summary;
  final VoidCallback onOpen;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.getJuzAmmaTitle(lang),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '${summary.percent}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.expand_less, size: 22),
                    tooltip: AppLocalizations.getJuzAmmaLibraryCollapseHint(lang),
                    visualDensity: VisualDensity.compact,
                    onPressed: onCollapse,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${AppLocalizations.getJuzAmmaMemorizedLabel(lang)}: '
                '${summary.memorizedAyahs} / ${summary.totalAyahs}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              if (summary.todayLine != null) ...[
                const SizedBox(height: 6),
                Text(
                  summary.todayLine!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
              if (summary.fridayLine != null) ...[
                const SizedBox(height: 6),
                Text(
                  summary.fridayLine!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsedStrip extends StatelessWidget {
  const _CollapsedStrip({
    required this.lang,
    required this.summary,
    required this.onOpen,
    required this.onExpand,
  });

  final String lang;
  final _LibrarySummaryData summary;
  final VoidCallback onOpen;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strip = AppLocalizations.formatJuzAmmaLibraryCollapsedStrip(
      lang,
      summary.percent,
      summary.stripDetail,
    );

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.expand_more, size: 22),
                tooltip: AppLocalizations.getJuzAmmaLibraryExpandHint(lang),
                visualDensity: VisualDensity.compact,
                onPressed: onExpand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
