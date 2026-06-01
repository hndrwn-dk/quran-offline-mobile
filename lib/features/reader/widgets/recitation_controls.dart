import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';

/// Fixed height so idle "Play surah" and active controls do not resize the header.
const double _surahRecitationBarHeight = 48;

/// Inline recitation controls for the surah header (no separate bottom player).
class SurahRecitationControls extends ConsumerWidget {
  final int surahId;
  final String surahName;
  final int verseCount;

  const SurahRecitationControls({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.verseCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final isThisSurah = audio.surahId == surahId;
    final showActiveBar = isThisSurah && audio.isActive;
    final isPlaying = isThisSurah && audio.isPlaying;

    if (!showActiveBar) {
      return SizedBox(
        height: _surahRecitationBarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => PlaybackActions.playSurah(
              context,
              ref,
              surahId,
              surahName: surahName,
            ),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Play surah'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
          ),
        ),
      );
    }

    final positionLabel = audio.isPlayingBismillah
        ? 'Bismillah / $verseCount'
        : 'Ayah ${audio.ayahNo ?? 1} / $verseCount';

    return SizedBox(
      height: _surahRecitationBarHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPlaying ? Icons.graphic_eq : Icons.pause_circle_outline,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                positionLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 22),
              tooltip: 'Previous ayah',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: notifier.previous,
            ),
            IconButton(
              iconSize: 28,
              icon: audio.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.stop_circle : Icons.play_circle,
                      color: colorScheme.primary,
                    ),
              tooltip: isPlaying ? 'Stop' : 'Play',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: audio.isLoading
                  ? null
                  : (isPlaying ? notifier.stop : notifier.restart),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 22),
              tooltip: 'Next ayah',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: notifier.next,
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: colorScheme.onSurfaceVariant),
              tooltip: 'Stop recitation',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
              onPressed: notifier.stop,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact prev / play-pause / next for the mushaf app bar while reciting.
class MushafRecitationAppBarActions extends ConsumerWidget {
  final int pageNo;

  const MushafRecitationAppBarActions({super.key, required this.pageNo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);
    if (!audio.isActive) return const SizedBox.shrink();

    final showOnPage = ref.watch(mushafPageShowsRecitationProvider(pageNo));
    if (showOnPage.valueOrNull != true) return const SizedBox.shrink();

    final notifier = ref.read(audioPlayerProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (audio.ayahNo != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              audio.isPlayingBismillah
                  ? '${audio.surahLabel ?? 'Surah'}'
                  : '${audio.surahLabel ?? 'Surah'} :${audio.ayahNo}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Previous ayah',
          onPressed: notifier.previous,
        ),
        IconButton(
          icon: Icon(
            audio.isPlaying ? Icons.stop : Icons.play_arrow,
          ),
          tooltip: audio.isPlaying ? 'Stop' : 'Play',
          onPressed: audio.isLoading
              ? null
              : (audio.isPlaying ? notifier.stop : notifier.restart),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          tooltip: 'Next ayah',
          onPressed: notifier.next,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Stop',
          onPressed: notifier.stop,
        ),
      ],
    );
  }
}
