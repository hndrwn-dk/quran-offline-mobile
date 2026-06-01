import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';

/// Shared entry points for starting recitation from the UI.
class PlaybackActions {
  PlaybackActions._();

  static Future<void> playAyah(
    BuildContext context,
    WidgetRef ref,
    int surahId,
    int ayahNo, {
    String? surahName,
  }) async {
    ref.read(recitationReturnSurfaceProvider.notifier).state =
        RecitationReturnSurface.reader;
    await _playWithOfflineHints(
      context,
      ref,
      surahId,
      surahName: surahName,
      playWholeSurah: false,
      play: () => ref
          .read(audioPlayerProvider.notifier)
          .playAyah(surahId, ayahNo, surahName: surahName),
    );
  }

  static Future<void> playSurah(
    BuildContext context,
    WidgetRef ref,
    int surahId, {
    String? surahName,
  }) async {
    ref.read(recitationReturnSurfaceProvider.notifier).state =
        RecitationReturnSurface.reader;
    await _playWithOfflineHints(
      context,
      ref,
      surahId,
      surahName: surahName,
      playWholeSurah: true,
      play: () => ref
          .read(audioPlayerProvider.notifier)
          .playSurah(surahId, surahName: surahName),
    );
  }

  static Future<void> _playWithOfflineHints(
    BuildContext context,
    WidgetRef ref,
    int surahId, {
    String? surahName,
    required bool playWholeSurah,
    required Future<void> Function() play,
  }) async {
    final reciter = ref.read(reciterProvider);
    final downloads = ref.read(audioDownloadProvider);
    final label = surahName ?? 'Surah $surahId';

    if (!downloads.isComplete(reciter.id, surahId)) {
      final db = ref.read(databaseProvider);
      final ayahCount = await db.getAyahCountForSurah(surahId);
      if (context.mounted) {
        AudioOfflinePrompts.showPreparingPlayback(
          context,
          ref,
          surahId: surahId,
          surahName: label,
          ayahCount: ayahCount,
          playWholeSurah: playWholeSurah,
        );
      }
    }

    await play();

    if (!context.mounted) return;
    AudioOfflinePrompts.showStreamingReminder(
      context,
      ref,
      surahId: surahId,
      surahName: label,
    );
  }

  /// Mushaf tap: plays the exact ayah from local cache when possible.
  static Future<void> playMushafAyah(
    BuildContext context,
    WidgetRef ref,
    int surahId,
    int ayahNo, {
    String? surahName,
  }) async {
    ref.read(recitationReturnSurfaceProvider.notifier).state =
        RecitationReturnSurface.mushaf;
    await ref
        .read(audioPlayerProvider.notifier)
        .playAyahExact(surahId, ayahNo, surahName: surahName);
    if (!context.mounted) return;
    final error = ref.read(audioPlayerProvider).error;
    if (error != null) {
      AudioOfflinePrompts.showNotSavedOnDevice(
        context,
        ref,
        surahId: surahId,
        surahName: surahName,
      );
    }
  }

  /// Stops recitation if a session is active (e.g. before opening mushaf mode).
  static Future<void> stopIfActive(WidgetRef ref) async {
    final audio = ref.read(audioPlayerProvider);
    if (audio.isActive) {
      await ref.read(audioPlayerProvider.notifier).stop();
    }
  }

  /// Triggers a surah download for the currently selected reciter.
  static Future<void> download(WidgetRef ref, int surahId) {
    final Reciter reciter = ref.read(reciterProvider);
    return ref
        .read(audioDownloadProvider.notifier)
        .downloadSurah(reciter, surahId);
  }
}
