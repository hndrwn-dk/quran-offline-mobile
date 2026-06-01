import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/settings/audio_downloads_screen.dart';

/// User-facing copy and snackbars for offline recitation downloads.
class AudioOfflinePrompts {
  AudioOfflinePrompts._();

  static const int totalSurahs = 114;

  /// Ayah count at or above which we warn before building a streaming playlist.
  static const int largeSurahAyahThreshold = 40;

  static void openDownloadsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AudioDownloadsScreen(),
      ),
    );
  }

  static void showSurahSaved(
    BuildContext context, {
    required String surahLabel,
    required int completedCount,
    String language = 'en',
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.recSurahSaved(
            surahLabel,
            completedCount,
            totalSurahs,
            language,
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showAllSurahsSaved(BuildContext context, {String language = 'en'}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.getRecitationText('all_surahs_saved', language),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Shown before starting playback when the surah is not fully cached.
  static void showPreparingPlayback(
    BuildContext context,
    WidgetRef ref, {
    required int surahId,
    required String surahName,
    required int ayahCount,
    required bool playWholeSurah,
  }) {
    final reciter = ref.read(reciterProvider);
    final downloads = ref.read(audioDownloadProvider);
    if (downloads.isComplete(reciter.id, surahId) ||
        downloads.isDownloading(reciter.id, surahId)) {
      return;
    }
    if (!context.mounted) return;

    final language = ref.read(settingsProvider).appLanguage;
    final isLarge = ayahCount >= largeSurahAyahThreshold;
    final actionLabel = playWholeSurah && isLarge
        ? AppLocalizations.getRecitationText('save_surah_action', language)
        : AppLocalizations.getRecitationText('save_action', language);

    String message;
    if (isLarge && playWholeSurah) {
      message = AppLocalizations.recPreparingLargeWhole(surahName, language);
    } else if (isLarge) {
      message = AppLocalizations.recPreparingLarge(surahName, language);
    } else {
      message = AppLocalizations.recPreparingSmall(surahName, language);
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: isLarge ? 7 : 5),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: () {
            ref
                .read(audioDownloadProvider.notifier)
                .downloadSurah(reciter, surahId);
          },
        ),
      ),
    );
  }

  /// After playback started while still streaming (not fully downloaded).
  static void showStreamingReminder(
    BuildContext context,
    WidgetRef ref, {
    required int surahId,
    String? surahName,
  }) {
    final reciter = ref.read(reciterProvider);
    final downloads = ref.read(audioDownloadProvider);
    if (downloads.isComplete(reciter.id, surahId) ||
        downloads.isDownloading(reciter.id, surahId)) {
      return;
    }
    if (!context.mounted) return;

    final language = ref.read(settingsProvider).appLanguage;
    final label = surahName ?? 'Surah $surahId';
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.recStreamingReminder(label, language),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: AppLocalizations.getRecitationText('save_action', language),
          onPressed: () {
            ref
                .read(audioDownloadProvider.notifier)
                .downloadSurah(reciter, surahId);
          },
        ),
      ),
    );
  }

  static void showNotSavedOnDevice(
    BuildContext context,
    WidgetRef ref, {
    required int surahId,
    String? surahName,
  }) {
    if (!context.mounted) return;
    final reciter = ref.read(reciterProvider);
    final language = ref.read(settingsProvider).appLanguage;
    final label = surahName ?? 'Surah $surahId';
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.recNotSavedOnDevice(label, language),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: AppLocalizations.getRecitationText('save_action', language),
          onPressed: () {
            ref
                .read(audioDownloadProvider.notifier)
                .downloadSurah(reciter, surahId);
          },
        ),
      ),
    );
  }

  static int completedCount(WidgetRef ref) {
    final reciter = ref.read(reciterProvider);
    return ref.read(audioDownloadProvider.notifier).completedCountForReciter(
          reciter.id,
        );
  }
}
