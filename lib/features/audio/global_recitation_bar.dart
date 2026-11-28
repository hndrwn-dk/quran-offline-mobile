import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/audio/recitation_primary_action.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
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

  static const double _capsuleHeight = 56;
  static const double _horizontalMargin = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(showGlobalRecitationBarProvider)) {
      return const SizedBox.shrink();
    }

    final audio = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaying = audio.isPlaying;
    final lang = ref.watch(settingsProvider).appLanguage;

    final title = AppLocalizations.formatMiniPlayerTitle(
      language: lang,
      surahLabel: audio.surahLabel,
      ayahNo: audio.ayahNo,
      isBismillah: audio.isPlayingBismillah,
    );

    final isDark = colorScheme.brightness == Brightness.dark;
    // Solid when the user asked for more contrast.
    final solid = MediaQuery.highContrastOf(context);
    final radius = BorderRadius.circular(_capsuleHeight / 2);

    final capsule = Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalMargin,
        6,
        _horizontalMargin,
        padForSystemBottomInset ? 12 : 8,
      ),
      child: DecoratedBox(
        key: const Key('global_recitation_capsule'),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            enabled: !solid,
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: colorScheme.card.withValues(alpha: solid ? 1 : 0.78),
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color: isDark
                      ? colorScheme.outlineVariant
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: _capsuleHeight,
                child: _buildControls(
                  context,
                  ref,
                  title,
                  lang,
                  audio,
                  notifier,
                  colorScheme,
                  isPlaying,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: AppLocalizations.formatMiniPlayerSemanticsLabel(lang, title),
      child: padForSystemBottomInset
          ? SafeArea(top: false, child: capsule)
          : capsule,
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    String title,
    String lang,
    AudioPlayerState audio,
    AudioPlayerNotifier notifier,
    ColorScheme colorScheme,
    bool isPlaying,
  ) {
    const buttonConstraints = BoxConstraints(minWidth: 40, minHeight: 44);
    // 40x44 targets; the default 48 leaves too little room for the title.
    final buttonStyle = IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 2),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => openPlayingRecitation(context, ref),
              borderRadius: BorderRadius.circular(_capsuleHeight / 2),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      Icon(
                        isPlaying ? Icons.graphic_eq : Icons.volume_up_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                    color: colorScheme.onSurface,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, size: 24),
            color: colorScheme.onSurface,
            tooltip: AppLocalizations.getActionTooltip('previous_ayah', lang),
            padding: EdgeInsets.zero,
            constraints: buttonConstraints,
            style: buttonStyle,
            onPressed: notifier.previous,
          ),
          IconButton(
            iconSize: 26,
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
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: colorScheme.primary,
                  ),
            tooltip: AppLocalizations.getActionTooltip(
              recitationPrimaryAction(isPlaying: isPlaying).tooltipKey,
              lang,
            ),
            padding: EdgeInsets.zero,
            constraints: buttonConstraints,
            style: buttonStyle,
            onPressed: audio.isLoading
                ? null
                : (isPlaying ? notifier.pause : notifier.restart),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 24),
            color: colorScheme.onSurface,
            tooltip: AppLocalizations.getActionTooltip('next_ayah', lang),
            padding: EdgeInsets.zero,
            constraints: buttonConstraints,
            style: buttonStyle,
            onPressed: notifier.next,
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: AppLocalizations.getActionTooltip('stop_recitation', lang),
            padding: EdgeInsets.zero,
            constraints: buttonConstraints,
            style: buttonStyle,
            onPressed: notifier.stop,
          ),
        ],
      ),
    );
  }
}
