import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';

/// Listens for completed surah downloads and shows app-wide snackbars.
class AudioDownloadNotifications extends ConsumerStatefulWidget {
  const AudioDownloadNotifications({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AudioDownloadNotifications> createState() =>
      _AudioDownloadNotificationsState();
}

class _AudioDownloadNotificationsState
    extends ConsumerState<AudioDownloadNotifications> {
  bool _bulkWasActive = false;
  bool _completedSeeded = false;
  Set<String> _knownCompleted = const {};
  Set<String> _knownFailed = const {};

  String _surahName(int surahId) {
    final surahs = ref.read(surahNamesProvider).valueOrNull;
    if (surahs != null) {
      for (final s in surahs) {
        if (s.id == surahId) return s.englishName;
      }
    }
    return 'Surah $surahId';
  }

  Set<String> _failedKeys(AudioDownloadsState state) {
    return state.active.entries
        .where((e) => e.value.failed)
        .map((e) => e.key)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AudioDownloadsState>(audioDownloadProvider, (previous, next) {
      if (!mounted) return;

      if (!_completedSeeded) {
        _knownCompleted = Set<String>.from(next.completed);
        _knownFailed = _failedKeys(next);
        _completedSeeded = true;
        _bulkWasActive = next.bulk != null;
        return;
      }

      final language = ref.read(settingsProvider).appLanguage;
      final added = next.completed.difference(_knownCompleted);
      if (added.isNotEmpty && next.bulk == null) {
        final reciter = ref.read(reciterProvider);
        for (final key in added) {
          if (!key.startsWith('${reciter.id}:')) continue;
          final surahId = int.tryParse(key.split(':').last);
          if (surahId == null) continue;
          final count = ref
              .read(audioDownloadProvider.notifier)
              .completedCountForReciter(reciter.id);
          AudioOfflinePrompts.showSurahSaved(
            context,
            surahLabel: _surahName(surahId),
            completedCount: count,
            language: language,
          );
        }
      }
      _knownCompleted = Set<String>.from(next.completed);

      final failedNow = _failedKeys(next);
      final newlyFailed = failedNow.difference(_knownFailed);
      if (newlyFailed.isNotEmpty && next.bulk == null) {
        final reciter = ref.read(reciterProvider);
        for (final key in newlyFailed) {
          if (!key.startsWith('${reciter.id}:')) continue;
          final surahId = int.tryParse(key.split(':').last);
          if (surahId == null) continue;
          AudioOfflinePrompts.showSaveFailed(
            context,
            ref,
            surahId: surahId,
            surahLabel: _surahName(surahId),
            language: language,
          );
        }
      }
      _knownFailed = failedNow;

      final bulkActive = next.bulk != null;
      if (_bulkWasActive && !bulkActive) {
        final reciter = ref.read(reciterProvider);
        final count = ref
            .read(audioDownloadProvider.notifier)
            .completedCountForReciter(reciter.id);
        if (count >= AudioOfflinePrompts.totalSurahs) {
          AudioOfflinePrompts.showAllSurahsSaved(context, language: language);
        }
      }
      _bulkWasActive = bulkActive;
    });

    return widget.child;
  }
}
