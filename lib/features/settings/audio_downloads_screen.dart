import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Manages per-surah recitation downloads for the selected reciter.
class AudioDownloadsScreen extends ConsumerStatefulWidget {
  const AudioDownloadsScreen({super.key});

  @override
  ConsumerState<AudioDownloadsScreen> createState() => _AudioDownloadsScreenState();
}

class _AudioDownloadsScreenState extends ConsumerState<AudioDownloadsScreen> {
  int _currentReciterBytes = 0;
  int _totalBytes = 0;
  List<ReciterStorageSummary> _allReciterStorage = const [];
  bool _storageLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStorage());
  }

  Future<void> _refreshStorage() async {
    final notifier = ref.read(audioDownloadProvider.notifier);
    final reciter = ref.read(reciterProvider);
    final current = await notifier.storageBytesForReciter(reciter.id);
    final total = await notifier.storageBytesTotal();
    final all = await notifier.storageSummariesForAllReciters();
    if (mounted) {
      setState(() {
        _currentReciterBytes = current;
        _totalBytes = total;
        _allReciterStorage = all;
        _storageLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<bool> _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final lang = ref.read(settingsProvider).appLanguage;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.getRecitationText('cancel', lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(AppLocalizations.getRecitationText('delete', lang)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _deleteReciter(String reciterId, String displayName) async {
    final lang = ref.read(settingsProvider).appLanguage;
    final ok = await _confirmDelete(
      context,
      title: AppLocalizations.recDeleteReciterTitle(displayName, lang),
      message: AppLocalizations.recDeleteReciterMessage(displayName, lang),
    );
    if (!ok || !mounted) return;
    await ref.read(audioDownloadProvider.notifier).deleteAllForReciter(reciterId);
    await _refreshStorage();
  }

  Future<void> _deleteAllReciters() async {
    final lang = ref.read(settingsProvider).appLanguage;
    final ok = await _confirmDelete(
      context,
      title: AppLocalizations.getRecitationText('delete_all_recitation_q', lang),
      message: AppLocalizations.recDeleteAllMessage(_formatBytes(_totalBytes), lang),
    );
    if (!ok || !mounted) return;
    await ref.read(audioDownloadProvider.notifier).deleteAllReciters();
    await _refreshStorage();
  }

  @override
  Widget build(BuildContext context) {
    final reciter = ref.watch(reciterProvider);
    final downloads = ref.watch(audioDownloadProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final savedCount = ref
        .read(audioDownloadProvider.notifier)
        .completedCountForReciter(reciter.id);
    final allSaved = savedCount >= AudioOfflinePrompts.totalSurahs;
    final bulk = downloads.bulk;
    final otherRecitersWithData = _allReciterStorage
        .where((s) => s.reciterId != reciter.id && s.hasFiles)
        .length;

    ref.listen<AudioDownloadsState>(audioDownloadProvider, (prev, next) {
      if (prev?.completed.length != next.completed.length ||
          prev?.active.length != next.active.length) {
        _refreshStorage();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.getRecitationText('recitation_downloads', appLanguage),
        ),
      ),
      body: surahsAsync.when(
        data: (surahs) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(
                context,
                reciter: reciter,
                colorScheme: colorScheme,
                savedCount: savedCount,
                allSaved: allSaved,
                bulk: bulk,
                otherRecitersWithData: otherRecitersWithData,
                appLanguage: appLanguage,
              )),
              if (_totalBytes > 0 || _allReciterStorage.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildPhoneStorageSection(
                    context,
                    colorScheme,
                    reciter,
                    appLanguage,
                  ),
                ),
              SliverList.builder(
                itemCount: surahs.length,
                itemBuilder: (context, index) {
                  final surah = surahs[index];
                  final isComplete = downloads.isComplete(reciter.id, surah.id);
                  final progress = downloads.progressFor(reciter.id, surah.id);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      child: Text('${surah.id}'),
                    ),
                    title: Text(surah.englishName),
                    subtitle: progress != null
                        ? Text(
                            progress.failed
                                ? AppLocalizations.getRecitationText(
                                    'failed_retry', appLanguage)
                                : AppLocalizations.recDownloadingProgress(
                                    progress.done, progress.total, appLanguage),
                            style: TextStyle(
                              color: progress.failed ? colorScheme.error : null,
                            ),
                          )
                        : Text(
                            AppLocalizations.getRecitationText(
                              isComplete ? 'saved_on_device' : 'not_saved',
                              appLanguage,
                            ),
                          ),
                    trailing: _buildTrailing(
                      reciter.id,
                      surah.id,
                      isComplete,
                      progress,
                      colorScheme,
                      appLanguage,
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppLocalizations.recError(e, appLanguage))),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Reciter reciter,
    required ColorScheme colorScheme,
    required int savedCount,
    required bool allSaved,
    required BulkDownloadProgress? bulk,
    required int otherRecitersWithData,
    required String appLanguage,
  }) {
    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reciter.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.recReciterSeparateHeader(reciter.name, appLanguage),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.recSavedForThisReciter(
              savedCount,
              AudioOfflinePrompts.totalSurahs,
              appLanguage,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          if (_storageLoading)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else ...[
            Text(
              AppLocalizations.recStorageForReciter(
                reciter.name,
                _formatBytes(_currentReciterBytes),
                appLanguage,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.recTotalAllReciters(
                _formatBytes(_totalBytes),
                appLanguage,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
            if (otherRecitersWithData > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  AppLocalizations.recOtherRecitersUseSpace(
                    otherRecitersWithData,
                    appLanguage,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ),
          ],
          if (bulk != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: bulk.fraction,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.recSavingSurah(
                '${bulk.currentSurahId ?? ''}',
                bulk.surahsDone,
                bulk.surahsTotal,
                appLanguage,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (!allSaved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: bulk != null
                  ? OutlinedButton(
                      onPressed: () => ref
                          .read(audioDownloadProvider.notifier)
                          .cancelBulkDownload(),
                      child: Text(
                        AppLocalizations.getRecitationText('cancel_save_all', appLanguage),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () => ref
                          .read(audioDownloadProvider.notifier)
                          .downloadAllSurahs(reciter),
                      icon: const Icon(Icons.download_for_offline),
                      label: Text(
                        AppLocalizations.getRecitationText('save_all_114', appLanguage),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.getRecitationText('recommended_smooth', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (!_storageLoading && _currentReciterBytes > 0) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: bulk != null
                  ? null
                  : () => _deleteReciter(reciter.id, reciter.name),
              icon: const Icon(Icons.delete_outline),
              label: Text(
                AppLocalizations.recDeleteAllAudioForReciter(reciter.name, appLanguage),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneStorageSection(
    BuildContext context,
    ColorScheme colorScheme,
    Reciter selectedReciter,
    String appLanguage,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.getRecitationText('storage_on_phone', appLanguage),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.getRecitationText('storage_phone_desc', appLanguage),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 8),
          if (_allReciterStorage.isEmpty && !_storageLoading)
            Text(
              AppLocalizations.getRecitationText('no_files_saved', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          else
            ..._allReciterStorage.map((summary) {
              final isSelected = summary.reciterId == selectedReciter.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(summary.displayName),
                  subtitle: Text(
                    _storageSummarySubtitle(summary, isSelected, appLanguage),
                  ),
                  trailing: summary.hasFiles
                      ? IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                          tooltip: AppLocalizations.getRecitationText('delete', appLanguage),
                          onPressed: () => _deleteReciter(
                            summary.reciterId,
                            summary.displayName,
                          ),
                        )
                      : null,
                ),
              );
            }),
          if (_totalBytes > 0) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteAllReciters,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(
                  AppLocalizations.recDeleteAllRecitationAudioBtn(
                    _formatBytes(_totalBytes),
                    appLanguage,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _storageSummarySubtitle(
    ReciterStorageSummary summary,
    bool isSelected,
    String appLanguage,
  ) {
    final parts = <String>[_formatBytes(summary.bytes)];
    if (summary.savedSurahCount > 0) {
      parts.add(
        AppLocalizations.recSurahsMarkedSaved(summary.savedSurahCount, appLanguage),
      );
    }
    if (isSelected) {
      parts.add(
        AppLocalizations.getRecitationText('selected_for_playback', appLanguage),
      );
    }
    return parts.join(' · ');
  }

  Widget _buildTrailing(
    String reciterId,
    int surahId,
    bool isComplete,
    DownloadProgress? progress,
    ColorScheme colorScheme,
    String appLanguage,
  ) {
    if (progress != null && !progress.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: progress.total == 0 ? null : progress.fraction,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: AppLocalizations.getRecitationText('cancel', appLanguage),
            onPressed: () => ref
                .read(audioDownloadProvider.notifier)
                .cancelDownload(reciterId, surahId),
          ),
        ],
      );
    }

    if (isComplete) {
      return IconButton(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        tooltip: AppLocalizations.getRecitationText('delete', appLanguage),
        onPressed: () async {
          await ref.read(audioDownloadProvider.notifier).deleteSurah(reciterId, surahId);
          await _refreshStorage();
        },
      );
    }

    final reciter = ref.read(reciterProvider);
    return IconButton(
      icon: Icon(
        progress?.failed == true ? Icons.refresh : Icons.download_outlined,
        color: colorScheme.primary,
      ),
      tooltip: AppLocalizations.getRecitationText('save', appLanguage),
      onPressed: () {
        ref.read(audioDownloadProvider.notifier).downloadSurah(reciter, surahId);
      },
    );
  }
}
