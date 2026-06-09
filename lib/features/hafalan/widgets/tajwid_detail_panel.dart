import 'package:flutter/material.dart';
import 'package:quran_offline/core/audio/phoneme_checker.dart';
import 'package:quran_offline/core/quran/tajweed_rule_parser.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

class TajwidDetailPanel extends StatefulWidget {
  const TajwidDetailPanel({
    super.key,
    required this.phonemeResult,
    required this.tajweedMap,
    required this.lang,
  });

  final PhonemeCheckResult phonemeResult;
  final TajweedRuleMap tajweedMap;
  final String lang;

  @override
  State<TajwidDetailPanel> createState() => _TajwidDetailPanelState();
}

class _TajwidDetailPanelState extends State<TajwidDetailPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.phonemeResult.isClean) {
      return _buildCleanBadge(context, colorScheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, colorScheme),
        if (_expanded) _buildDetailContent(context, colorScheme),
      ],
    );
  }

  Widget _buildCleanBadge(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppLocalizations.getSetoranTajwidClean(widget.lang),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final issueCount = widget.phonemeResult.laamShamsViolations.length +
        widget.phonemeResult.ghunnahViolations.length +
        (widget.phonemeResult.possibleMadLazimRush ? 1 : 0);

    final accent = colorScheme.tertiary;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.formatSetoranTajwidIssueCount(
                  widget.lang,
                  issueCount,
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.phonemeResult.wordScores.isNotEmpty) ...[
            _buildWordScoresRow(context, colorScheme),
            const SizedBox(height: 12),
          ],
          for (final v in widget.phonemeResult.laamShamsViolations) ...[
            _buildViolationTile(
              context: context,
              colorScheme: colorScheme,
              rule: AppLocalizations.getSetoranTajwidLaamShams(widget.lang),
              arabicContext: v.arabicWord,
              expected: v.expectedToken,
              heard: v.heardToken,
              tip: v.tipId,
              isMajor: true,
            ),
            const SizedBox(height: 8),
          ],
          for (final v in widget.phonemeResult.ghunnahViolations) ...[
            _buildViolationTile(
              context: context,
              colorScheme: colorScheme,
              rule: AppLocalizations.getSetoranTajwidGhunnah(widget.lang),
              arabicContext: v.arabicContext,
              expected: v.expectedPattern,
              heard: v.heardPattern,
              tip: TajweedSpan(
                arabicText: '',
                rule: TajweedClass.ghunnah,
                spanIndex: 0,
              ).tipId(widget.lang),
              isMajor: false,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.phonemeResult.possibleMadLazimRush)
            _buildMadLazimTile(context, colorScheme),
          const SizedBox(height: 4),
          _buildTajweedScoreBadge(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildWordScoresRow(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.getSetoranTajwidPerWord(widget.lang),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.phonemeResult.wordScores.map((w) {
            final col = w.isCorrect
                ? colorScheme.primary
                : w.isMispronounced
                    ? colorScheme.tertiary
                    : colorScheme.error;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: col.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  if (w.arabicWord.isNotEmpty)
                    Text(
                      w.arabicWord,
                      style: TextStyle(
                        fontSize: 16,
                        color: col,
                        fontFamily: 'UthmanicHafsV22',
                        fontFamilyFallback: const ['UthmanicHafs'],
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  Text(
                    '${(w.similarity * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: col,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildViolationTile({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String rule,
    required String arabicContext,
    required String expected,
    required String heard,
    required String tip,
    required bool isMajor,
  }) {
    final col = isMajor ? colorScheme.error : colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: col, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rule,
                  style: TextStyle(
                    fontSize: 11,
                    color: col,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isMajor
                      ? AppLocalizations.getSetoranTajwidMajor(widget.lang)
                      : AppLocalizations.getSetoranTajwidMinor(widget.lang),
                  style: TextStyle(fontSize: 10, color: col),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _phonemeChip(
                expected,
                colorScheme.primary,
                AppLocalizations.getSetoranTajwidExpected(widget.lang),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '->',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              _phonemeChip(
                heard,
                col,
                AppLocalizations.getSetoranTajwidHeard(widget.lang),
              ),
            ],
          ),
          if (arabicContext.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              arabicContext,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'UthmanicHafsV22',
                fontFamilyFallback: ['UthmanicHafs'],
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _phonemeChip(String text, Color col, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, color: col.withValues(alpha: 0.7)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: col.withValues(alpha: 0.3)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: col,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMadLazimTile(BuildContext context, ColorScheme colorScheme) {
    final col = colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: col, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TajweedSpan(
              arabicText: '',
              rule: TajweedClass.madda_necessary,
              spanIndex: 0,
            ).labelId(widget.lang),
            style: TextStyle(
              fontSize: 12,
              color: col,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.getSetoranTajwidMadLazimRush(widget.lang),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTajweedScoreBadge(BuildContext context, ColorScheme colorScheme) {
    final score = widget.phonemeResult.phonemeTajweedScore;
    final col = score >= 80
        ? colorScheme.primary
        : score >= 60
            ? colorScheme.tertiary
            : colorScheme.error;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          AppLocalizations.getSetoranTajwidScoreLabel(widget.lang),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: col.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$score / 100',
            style: TextStyle(
              fontSize: 12,
              color: col,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
