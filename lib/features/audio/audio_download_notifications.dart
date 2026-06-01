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

  @override
  Widget build(BuildContext context) {
    ref.listen<AudioDownloadsState>(audioDownloadProvider, (previous, next) {
      if (!mounted) return;

      final language = ref.read(settingsProvider).appLanguage;
      final prevCompleted = previous?.completed ?? const {};
      final added = next.completed.difference(prevCompleted);
      if (added.isNotEmpty && next.bulk == null) {
        final reciter = ref.read(reciterProvider);
        final surahs = ref.read(surahNamesProvider).valueOrNull;
        for (final key in added) {
          if (!key.startsWith('${reciter.id}:')) continue;
          final surahId = int.tryParse(key.split(':').last);
          if (surahId == null) continue;
          var name = 'Surah $surahId';
          if (surahs != null) {
            for (final s in surahs) {
              if (s.id == surahId) {
                name = s.englishName;
                break;
              }
            }
          }
          final count = ref
              .read(audioDownloadProvider.notifier)
              .completedCountForReciter(reciter.id);
          AudioOfflinePrompts.showSurahSaved(
            context,
            surahLabel: name,
            completedCount: count,
            language: language,
          );
        }
      }

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
