import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/support_provider.dart';
import 'package:quran_offline/core/support/support_prompt_policy.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/support/support_sheet.dart';

class ReadingMilestoneSlot extends ConsumerWidget {
  const ReadingMilestoneSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(readingCoverageProvider).card;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: card == null
          ? const SizedBox(width: double.infinity)
          : _ReadingMilestoneCard(card: card),
    );
  }
}

class _ReadingMilestoneCard extends ConsumerWidget {
  const _ReadingMilestoneCard({required this.card});

  final ActiveReadingCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final completed = card.milestone.completedJuz.clamp(0, 30);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.supportAlhamdulillah(language),
                    style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.supportMilestoneTitle(language, card.milestone),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.supportMilestoneSubtitle(language, completed),
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: completed / 30,
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                ),
              ),
              if (card.askVisible) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(AppLocalizations.supportAskBody(language)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => showSupportSheet(context),
                        child: Text(AppLocalizations.supportAskButton(language)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref.read(readingCoverageProvider).dismissCard(),
                        child: Text(AppLocalizations.supportClose(language)),
                      ),
                    ),
                  ],
                ),
              ] else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ref.read(readingCoverageProvider).dismissCard(),
                    child: Text(AppLocalizations.supportClose(language)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
