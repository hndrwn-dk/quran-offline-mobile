import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';

/// Bismillah block shown before ayah 1 (surahs other than 1 and 9).
class ReaderBismillahBlock extends ConsumerWidget {
  final int surahId;

  const ReaderBismillahBlock({super.key, required this.surahId});

  void _togglePlay(BuildContext context, WidgetRef ref, AudioPlayerState audio) {
    final notifier = ref.read(audioPlayerProvider.notifier);
    if (audio.surahId == surahId && audio.isPlayingBismillah) {
      if (audio.isPlaying) {
        notifier.stop();
      } else {
        notifier.restart();
      }
      return;
    }
    final surahs = ref.read(surahNamesProvider).valueOrNull;
    final surahName = surahs
        ?.firstWhere(
          (s) => s.id == surahId,
          orElse: () => surahs.first,
        )
        .englishName;
    PlaybackActions.playAyah(
      context,
      ref,
      surahId,
      Bismillah.audioAyahNo,
      surahName: surahName,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final audio = ref.watch(audioPlayerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReciting = audio.surahId == surahId && audio.isPlayingBismillah;
    final isPlayingThis = isReciting && audio.isPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isReciting
              ? colorScheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isReciting
                ? colorScheme.primary.withValues(alpha: 0.40)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isReciting
                      ? (isPlayingThis
                          ? Icons.graphic_eq
                          : Icons.volume_up_outlined)
                      : Icons.volume_up_outlined,
                  size: 16,
                  color: isReciting
                      ? colorScheme.primary
                      : Colors.transparent,
                ),
                IconButton(
                  icon: Icon(
                    isPlayingThis
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                    size: 20,
                  ),
                  color: isReciting
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Play Bismillah',
                  onPressed: () => _togglePlay(context, ref, audio),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.centerRight,
                child: SelectableText(
                  Bismillah.arabic,
                  style: TextStyle(
                    fontSize: settings.arabicFontSize * 1.1,
                    fontFamily: 'UthmanicHafsV22',
                    fontFamilyFallback: const ['UthmanicHafs'],
                    height: 1.7,
                    color: colorScheme.onSurface,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            if (settings.showTransliteration) ...[
              const SizedBox(height: 8),
              SelectableText(
                Bismillah.transliteration,
                style: TextStyle(
                  fontSize: settings.translationFontSize * 0.85,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SelectableText(
              Bismillah.getTranslation(settings.language),
              style: TextStyle(
                fontSize: settings.translationFontSize,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
