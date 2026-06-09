import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/juz_amma_hafalan.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/juz_amma_hafalan_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/hafalan/friday_setoran_screen.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

class JuzAmmaScreen extends ConsumerWidget {
  const JuzAmmaScreen({super.key, this.showBackButton = true});

  /// False when shown as a root bottom-nav tab.
  final bool showBackButton;

  static const List<int> _surahOrder = [
    114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101,
    100, 99, 98, 97, 96, 95, 94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84,
    83, 82, 81, 80, 79, 78,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final mode = ref.watch(juzAmmaHafalanModeProvider);
    final start = ref.watch(juzAmmaProgramStartProvider);
    final taskAsync = ref.watch(juzAmmaTodayTaskProvider);
    final progressAsync = ref.watch(juzAmmaProgressSummaryProvider);
    final memorizedAsync = ref.watch(juzAmmaMemorizedProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final isFriday = DateTime.now().weekday == DateTime.friday;
    final queueAsync = ref.watch(fridaySetoranQueueProvider);
    final setoranDone = queueAsync.maybeWhen(
      data: (q) => q.where((e) => e.isDone).length,
      orElse: () => 0,
    );
    final setoranTotal = queueAsync.maybeWhen(
      data: (q) => q.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton && Navigator.canPop(context)
            ? const BackButton()
            : null,
        title: Text(AppLocalizations.getJuzAmmaTitle(lang)),
      ),
      body: surahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (surahs) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                AppLocalizations.getJuzAmmaSubtitle(lang),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.getJuzAmmaMethodTip(lang),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.45,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<JuzAmmaHafalanMode>(
                segments: [
                  ButtonSegment(
                    value: JuzAmmaHafalanMode.program,
                    label: Text(AppLocalizations.getJuzAmmaModeProgram(lang)),
                  ),
                  ButtonSegment(
                    value: JuzAmmaHafalanMode.free,
                    label: Text(AppLocalizations.getJuzAmmaModeFree(lang)),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) {
                  ref.read(juzAmmaHafalanModeProvider.notifier).setMode(s.first);
                },
              ),
              const SizedBox(height: 16),
              if (mode == JuzAmmaHafalanMode.program) ...[
                if (start == null) ...[
                  FilledButton.tonal(
                    onPressed: () {
                      ref.read(juzAmmaProgramStartProvider.notifier).startProgram();
                    },
                    child: Text(AppLocalizations.getJuzAmmaStartProgram(lang)),
                  ),
                  if (isFriday) ...[
                    const SizedBox(height: 12),
                    _TodayTaskCard(
                      task: const HafalanDayTask(kind: HafalanDayKind.murojaah),
                      lang: lang,
                      setoranDone: setoranDone,
                      setoranTotal: setoranTotal,
                      onOpen: () => _openFridaySetoran(context),
                    ),
                  ],
                ] else
                  taskAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (task) => _TodayTaskCard(
                      task: task,
                      lang: lang,
                      setoranDone: setoranDone,
                      setoranTotal: setoranTotal,
                      onOpen: task.unit != null
                          ? () => _openUnit(context, ref, task.unit!)
                          : () => _openFridaySetoran(context),
                    ),
                  ),
                const SizedBox(height: 8),
              ] else if (isFriday) ...[
                _TodayTaskCard(
                  task: const HafalanDayTask(kind: HafalanDayKind.murojaah),
                  lang: lang,
                  setoranDone: setoranDone,
                  setoranTotal: setoranTotal,
                  onOpen: () => _openFridaySetoran(context),
                ),
                const SizedBox(height: 8),
              ],
              progressAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) {
                  final pct = (p.ayahFraction * 100).round();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.getJuzAmmaMemorizedLabel(lang)}: ${p.memorizedAyahs} / ${p.totalAyahs} ($pct%)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: p.ayahFraction,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      if (mode == JuzAmmaHafalanMode.program) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${p.completedUnits} / ${p.totalUnits} unit program',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              ..._surahOrder.map((surahId) {
                final surah = surahs.firstWhere(
                  (s) => s.id == surahId,
                  orElse: () => surahs.first,
                );
                final memorized = memorizedAsync.valueOrNull ?? {};
                final count = memorized
                    .where((k) => k.startsWith('$surahId:'))
                    .length;
                final total = _ayahCount(surahId);
                final frac = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final source = SurahSource(surahId);
                        ref.read(readerSourceProvider.notifier).state = source;
                        openReaderScreen(context, ref);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    surah.englishName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '$count / $total',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                value: frac,
                                strokeWidth: 4,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static int _ayahCount(int surahId) {
    const counts = {
      78: 40, 79: 46, 80: 42, 81: 29, 82: 19, 83: 36, 84: 25, 85: 22,
      86: 17, 87: 19, 88: 26, 89: 30, 90: 20, 91: 15, 92: 21, 93: 11,
      94: 8, 95: 8, 96: 19, 97: 5, 98: 8, 99: 8, 100: 11, 101: 11,
      102: 8, 103: 3, 104: 9, 105: 5, 106: 4, 107: 7, 108: 3, 109: 6,
      110: 3, 111: 5, 112: 4, 113: 5, 114: 6,
    };
    return counts[surahId] ?? 0;
  }

  void _openUnit(BuildContext context, WidgetRef ref, JuzAmmaUnit unit) {
    final source = SurahSource(unit.surah, targetAyahNo: unit.from);
    ref.read(readerSourceProvider.notifier).state = source;
    ref.read(targetAyahProvider.notifier).state = unit.from;
    openReaderScreen(context, ref);
  }

  void _openFridaySetoran(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FridaySetoranScreen(),
      ),
    );
  }
}

class _TodayTaskCard extends StatelessWidget {
  const _TodayTaskCard({
    required this.task,
    required this.lang,
    required this.onOpen,
    this.setoranDone = 0,
    this.setoranTotal = 0,
  });

  final HafalanDayTask task;
  final String lang;
  final VoidCallback onOpen;
  final int setoranDone;
  final int setoranTotal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String title;
    final String? subtitle;

    switch (task.kind) {
      case HafalanDayKind.newMemorization:
        title = AppLocalizations.getJuzAmmaTodayNew(lang);
        final u = task.unit!;
        subtitle = AppLocalizations.formatJuzAmmaAyahRef(
          u.surah,
          u.from,
          u.to,
          lang,
        );
      case HafalanDayKind.murojaah:
        title = AppLocalizations.getJuzAmmaTodayMurojaah(lang);
        subtitle = setoranTotal > 0
            ? AppLocalizations.getFridaySetoranProgressSubtitle(
                lang,
                setoranDone,
                setoranTotal,
              )
            : AppLocalizations.getJuzAmmaFridaySetoranHint(lang);
      case HafalanDayKind.tahsin:
        title = AppLocalizations.getJuzAmmaTodayTahsin(
          lang,
          task.tahsinDay,
          task.tahsinTotal,
        );
        subtitle = null;
      case HafalanDayKind.completed:
        title = AppLocalizations.getJuzAmmaProgramComplete(lang);
        subtitle = null;
      case HafalanDayKind.notStarted:
        title = AppLocalizations.getJuzAmmaStartProgram(lang);
        subtitle = null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            if (task.kind != HafalanDayKind.notStarted &&
                task.kind != HafalanDayKind.completed) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onOpen,
                child: Text(
                  task.kind == HafalanDayKind.murojaah
                      ? AppLocalizations.getJuzAmmaOpenFridaySetoran(lang)
                      : AppLocalizations.getJuzAmmaOpenTarget(lang),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
