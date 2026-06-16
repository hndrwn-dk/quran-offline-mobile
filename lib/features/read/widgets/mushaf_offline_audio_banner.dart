import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/mushaf_hints_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';

/// Dismissible banner when recitation for visible surahs is not fully saved.
class MushafOfflineAudioBanner extends ConsumerWidget {
  const MushafOfflineAudioBanner({
    super.key,
    required this.pageNo,
  });

  final int pageNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);
    if (audio.isActive) return const SizedBox.shrink();

    final reciter = ref.watch(reciterProvider);
    final downloads = ref.watch(audioDownloadProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final lang = ref.watch(settingsProvider).appLanguage;

    final dismissed = ref.watch(mushafAudioHintDismissedProvider(reciter.id));
    if (dismissed.value == true) return const SizedBox.shrink();

    if (ref.read(audioDownloadProvider.notifier).hasAllSurahsForReciter(
          reciter.id,
        )) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<int>>(
      future: MushafLayout.getSurahIdsForPage(pageNo),
      builder: (context, snapshot) {
        final surahIds = snapshot.data ?? [];
        if (surahIds.isEmpty) return const SizedBox.shrink();

        final missing = surahIds
            .where((id) => !downloads.isComplete(reciter.id, id))
            .toList();
        if (missing.isEmpty) return const SizedBox.shrink();

        final saveLabel = AppLocalizations.getMushafSaveSurahAction(
          lang,
          plural: missing.length > 1,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.download_for_offline_outlined,
                      size: 18,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.getMushafAudioHint(lang),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            height: 1.35,
                            fontSize: 12,
                          ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      if (missing.length == 1) {
                        ref
                            .read(audioDownloadProvider.notifier)
                            .downloadSurah(reciter, missing.first);
                      } else {
                        AudioOfflinePrompts.openDownloadsScreen(context);
                      }
                    },
                    child: Text(saveLabel),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    tooltip: AppLocalizations.getActionTooltip('close', lang),
                    onPressed: () => dismissMushafAudioHint(ref, reciter.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
