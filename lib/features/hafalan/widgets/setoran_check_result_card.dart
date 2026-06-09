import 'package:flutter/material.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/hafalan/models/setoran_check_feedback.dart';

class SetoranCheckResultCard extends StatelessWidget {
  const SetoranCheckResultCard({
    super.key,
    required this.feedback,
    required this.lang,
  });

  final SetoranCheckFeedback feedback;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, title, bg, fg, border) = _style(colorScheme);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: fg, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                  ),
                ),
              ],
            ),
            if (feedback.transcript.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.formatSetoranHeardTranscript(
                  lang,
                  feedback.transcript,
                ),
                textDirection: _textDirection(feedback.transcript),
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
              ),
            ],
            if (feedback.score != null &&
                feedback.kind == SetoranCheckFeedbackKind.incorrect) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.formatSetoranMatchScore(lang, feedback.score!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextDirection _textDirection(String text) {
    for (final codeUnit in text.runes) {
      if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) {
        return TextDirection.rtl;
      }
    }
    return TextDirection.ltr;
  }

  (IconData, String, Color, Color, Color) _style(ColorScheme colorScheme) {
    return switch (feedback.kind) {
      SetoranCheckFeedbackKind.correct => (
          Icons.check_circle_rounded,
          AppLocalizations.getSetoranSpeechCorrect(lang),
          colorScheme.primaryContainer.withValues(alpha: 0.55),
          colorScheme.onPrimaryContainer,
          colorScheme.primary.withValues(alpha: 0.45),
        ),
      SetoranCheckFeedbackKind.incorrect => (
          Icons.highlight_off_rounded,
          AppLocalizations.getSetoranSpeechRetry(lang),
          colorScheme.errorContainer.withValues(alpha: 0.5),
          colorScheme.onErrorContainer,
          colorScheme.error.withValues(alpha: 0.5),
        ),
      SetoranCheckFeedbackKind.wrongLanguage => (
          Icons.translate_rounded,
          AppLocalizations.getSetoranSpeechWrongLanguage(lang),
          colorScheme.tertiaryContainer.withValues(alpha: 0.55),
          colorScheme.onTertiaryContainer,
          colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      SetoranCheckFeedbackKind.empty => (
          Icons.mic_off_outlined,
          AppLocalizations.getSetoranSpeechUncertain(lang),
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          colorScheme.onSurfaceVariant,
          colorScheme.outlineVariant,
        ),
      SetoranCheckFeedbackKind.uncertain => (
          Icons.help_outline_rounded,
          AppLocalizations.getSetoranSpeechUncertain(lang),
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          colorScheme.onSurfaceVariant,
          colorScheme.outlineVariant,
        ),
    };
  }
}
