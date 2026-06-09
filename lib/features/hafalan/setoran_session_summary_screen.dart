import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/juz_amma_hafalan.dart';
import 'package:quran_offline/core/providers/juz_amma_hafalan_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/hafalan/models/setoran_session_summary.dart';

class SetoranSessionSummaryScreen extends ConsumerWidget {
  const SetoranSessionSummaryScreen({
    super.key,
    required this.unit,
    required this.summary,
    required this.surahLabel,
    required this.ayahRef,
  });

  final JuzAmmaUnit unit;
  final SetoranSessionSummary summary;
  final String surahLabel;
  final String ayahRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    final statusLabel = summary.needsImprovement
        ? AppLocalizations.getSetoranSummaryNeedsWork(lang)
        : AppLocalizations.getSetoranSummaryReady(lang);
    final statusColor =
        summary.needsImprovement ? colorScheme.tertiary : colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.getSetoranSummaryTitle(lang)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surahLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            ayahRef,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreRing(
                        label: AppLocalizations.getSetoranSummaryAyahProgress(
                          lang,
                        ),
                        value: summary.revealedCount,
                        max: summary.totalAyahs,
                        color: colorScheme.primary,
                        displayAsFraction: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ScoreRing(
                        label: AppLocalizations.getSetoranSummaryTextScore(
                          lang,
                        ),
                        value: summary.avgTextScore,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ScoreRing(
                        label: AppLocalizations.getSetoranSummaryTajwidScore(
                          lang,
                        ),
                        value: summary.avgTajwidScore,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoBanner(
                  lang: lang,
                  summary: summary,
                  colorScheme: colorScheme,
                ),
                if (summary.errorCount > 0) ...[
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.getSetoranSummaryRetryAyahs(lang),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.formatSetoranSummaryErrorCount(
                      lang,
                      summary.errorCount,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (summary.topTajwidNotes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.getSetoranSummaryMainNotes(lang),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  for (final note in summary.topTajwidNotes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TajwidNoteTile(
                        note: note,
                        lang: lang,
                        colorScheme: colorScheme,
                      ),
                    ),
                ],
                if (summary.reviewAyahIndices.isNotEmpty &&
                    summary.errorCount == 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.getSetoranSummaryReviewHint(lang),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary.reviewAyahIndices.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          SetoranSummaryResult.retryAyah,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        AppLocalizations.getSetoranSummaryTryAgain(lang),
                      ),
                    ),
                  if (summary.reviewAyahIndices.isNotEmpty)
                    const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: summary.allRevealed
                        ? () async {
                            await markFridaySetoranDone(ref, unit);
                            if (context.mounted) {
                              Navigator.pop(
                                context,
                                SetoranSummaryResult.markedDone,
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.check),
                    label: Text(
                      AppLocalizations.getFridaySetoranMarkDone(lang),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.label,
    required this.value,
    required this.color,
    this.max,
    this.displayAsFraction = false,
  });

  final String label;
  final int? value;
  final int? max;
  final Color color;
  final bool displayAsFraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = value != null;
    final progress = displayAsFraction && max != null && max! > 0
        ? (value! / max!).clamp(0.0, 1.0)
        : hasValue
            ? (value! / 100).clamp(0.0, 1.0)
            : 0.0;

    final centerText = !hasValue
        ? '-'
        : displayAsFraction && max != null
            ? '$value/$max'
            : '$value';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: hasValue ? progress : 0,
                  strokeWidth: 5,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
                Text(
                  centerText,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.lang,
    required this.summary,
    required this.colorScheme,
  });

  final String lang;
  final SetoranSessionSummary summary;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final positive = summary.allRevealed && !summary.needsImprovement;
    final bg = positive
        ? colorScheme.primaryContainer.withValues(alpha: 0.45)
        : colorScheme.tertiaryContainer.withValues(alpha: 0.4);
    final fg = positive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: positive
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            positive ? Icons.check_circle_outline : Icons.info_outline,
            color: fg,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.getSetoranSummaryBannerBody(
                lang,
                summary.revealedCount,
                summary.totalAyahs,
                summary.topTajwidNotes.length,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fg,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TajwidNoteTile extends StatelessWidget {
  const _TajwidNoteTile({
    required this.note,
    required this.lang,
    required this.colorScheme,
  });

  final TajwidSummaryNote note;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final col = note.isMajor ? colorScheme.error : colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: col, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.formatSetoranSummaryAyahLabel(
                  lang,
                  note.ayahNo,
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  note.ruleLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: col,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                note.isMajor
                    ? AppLocalizations.getSetoranTajwidMajor(lang)
                    : AppLocalizations.getSetoranTajwidMinor(lang),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: col,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
