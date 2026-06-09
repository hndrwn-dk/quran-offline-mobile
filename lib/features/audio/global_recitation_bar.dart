import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/audio/open_playing_recitation.dart';
import 'package:quran_offline/features/audio/recitation_navigation_logic.dart';

/// Whether the global bar should show (hidden when inline controls are on screen).
final showGlobalRecitationBarProvider = Provider<bool>((ref) {
  final audio = ref.watch(audioPlayerProvider);
  if (!audio.isActive) return false;

  final readerSource = ref.watch(readerSourceProvider);
  final splitLayout = ref.watch(readerSplitLayoutProvider);
  final onReadTab = ref.watch(currentTabProvider) == AppTab.read;
  final pushedReaderOpen = ref.watch(readerScreenVisibleProvider);

  List<Verse>? juzVerses;
  if (readerSource is JuzSource) {
    juzVerses =
        ref.watch(readerVersesProvider(readerSource)).valueOrNull;
  }

  final hideForInline = shouldHideGlobalRecitationBar(
    audioActive: audio.isActive,
    playingSurahId: audio.surahId,
    readerSource: readerSource,
    splitLayout: splitLayout,
    onReadTab: onReadTab,
    readerScreenVisible: pushedReaderOpen,
    juzVerses: juzVerses,
  );

  return !hideForInline;
});

/// Mini player shown above the home bottom nav (and on screens without inline controls).
class GlobalRecitationBar extends ConsumerWidget {
  /// When false, omit bottom [SafeArea] padding (use above [NavigationBar] on home).
  const GlobalRecitationBar({
    super.key,
    this.padForSystemBottomInset = true,
  });

  final bool padForSystemBottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(showGlobalRecitationBarProvider)) {
      return const SizedBox.shrink();
    }

    final audio = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaying = audio.isPlaying;

    final title = audio.isPlayingBismillah
        ? '${audio.surahLabel ?? 'Surah'} · Bismillah'
        : '${audio.surahLabel ?? 'Surah'} · Ayah ${audio.ayahNo ?? 1}';

    return Semantics(
      container: true,
      label: 'Recitation mini player, $title. Double tap to open.',
      child: Material(
        elevation: 8,
        color: colorScheme.surfaceContainerHigh,
        child: padForSystemBottomInset
            ? SafeArea(
                top: false,
                child: _buildControls(
                  context,
                  ref,
                  title,
                  audio,
                  notifier,
                  colorScheme,
                  isPlaying,
                ),
              )
            : _buildControls(
                context,
                ref,
                title,
                audio,
                notifier,
                colorScheme,
                isPlaying,
              ),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    String title,
    AudioPlayerState audio,
    AudioPlayerNotifier notifier,
    ColorScheme colorScheme,
    bool isPlaying,
  ) {
    return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => openPlayingRecitation(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPlaying
                                ? Icons.graphic_eq
                                : Icons.volume_up_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 22,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 22),
                  tooltip: 'Previous ayah',
                  visualDensity: VisualDensity.compact,
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
                  onPressed: audio.isLoading
                      ? null
                      : (isPlaying ? notifier.stop : notifier.restart),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 22),
                  tooltip: 'Next ayah',
                  visualDensity: VisualDensity.compact,
                  onPressed: notifier.next,
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Stop recitation',
                  visualDensity: VisualDensity.compact,
                  onPressed: notifier.stop,
                ),
              ],
            ),
          );
  }
}
