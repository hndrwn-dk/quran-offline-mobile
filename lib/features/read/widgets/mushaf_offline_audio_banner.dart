import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';

/// Banner on mushaf pages when recitation for visible surahs is not fully saved.
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

        final saveLabel =
            missing.length == 1 ? 'Save surah' : 'Save surahs';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.download_for_offline_outlined,
                    size: 22,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Save audio on your device for instant playback without loading spinners.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            height: 1.35,
                          ),
                    ),
                  ),
                  TextButton(
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
