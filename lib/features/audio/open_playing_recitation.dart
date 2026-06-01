import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/mushaf_navigation_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/features/audio/recitation_navigation_logic.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';

/// Opens the screen for whatever is currently playing (reader or mushaf).
Future<void> openPlayingRecitation(BuildContext context, WidgetRef ref) async {
  final audio = ref.read(audioPlayerProvider);
  final surahId = audio.surahId;
  final strategy = resolveRecitationOpenStrategy(
    audioActive: audio.isActive,
    playingSurahId: surahId,
    returnSurface: ref.read(recitationReturnSurfaceProvider),
    mushafSessionActive: ref.read(mushafSessionActiveProvider),
    readerScreenVisible: ref.read(readerScreenVisibleProvider),
    readerSplitLayout: ref.read(readerSplitLayoutProvider),
  );
  if (strategy == RecitationOpenStrategy.none || surahId == null) return;

  ref.read(currentTabProvider.notifier).state = 0;

  if (strategy == RecitationOpenStrategy.jumpMushaf ||
      strategy == RecitationOpenStrategy.pushMushaf) {
    final targetAyah = _mushafTargetAyah(audio);
    final db = ref.read(databaseProvider);
    final lookupAyah =
        targetAyah == Bismillah.audioAyahNo ? 1 : (targetAyah ?? 1);
    final pageNo = await db.getPageForAyah(surahId, lookupAyah) ?? 1;

    if (strategy == RecitationOpenStrategy.jumpMushaf) {
      requestMushafJump(
        ref,
        pageNo: pageNo,
        surahId: surahId,
        ayahNo: targetAyah,
      );
      return;
    }

    if (!context.mounted) return;
    await _openMushaf(context, ref, surahId, audio, pageNo: pageNo);
    return;
  }

  await _openReader(context, ref, surahId, audio, strategy);
}

int _readerScrollAyah(AudioPlayerState audio) {
  if (audio.ayahNo == null) return 1;
  if (audio.ayahNo == Bismillah.audioAyahNo) return 1;
  return audio.ayahNo!;
}

int? _mushafTargetAyah(AudioPlayerState audio) {
  if (audio.isPlayingBismillah) return Bismillah.audioAyahNo;
  return audio.ayahNo;
}

Future<void> _openReader(
  BuildContext context,
  WidgetRef ref,
  int surahId,
  AudioPlayerState audio,
  RecitationOpenStrategy strategy,
) async {
  final scrollAyah = _readerScrollAyah(audio);

  if (strategy == RecitationOpenStrategy.jumpReader) {
    requestReaderJump(ref, surahId: surahId, ayahNo: scrollAyah);
    return;
  }

  if (!context.mounted) return;
  ref.read(readerSourceProvider.notifier).state =
      SurahSource(surahId, targetAyahNo: scrollAyah);
  ref.read(targetAyahProvider.notifier).state = scrollAyah;
  await openReaderScreen(context, ref);
}

Future<void> _openMushaf(
  BuildContext context,
  WidgetRef ref,
  int surahId,
  AudioPlayerState audio, {
  required int pageNo,
}) async {
  final targetAyah = _mushafTargetAyah(audio);

  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => MushafPageView(
        initialPage: pageNo,
        targetSurahId: surahId,
        targetAyahNo: targetAyah,
      ),
    ),
  );
}
