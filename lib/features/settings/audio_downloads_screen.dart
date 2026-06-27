import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';

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
    final topTint = HomeBackdrop.topTint(colorScheme);
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
      backgroundColor: topTint,
      appBar: AppBar(
        backgroundColor: topTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.getRecitationText('recitation_downloads', appLanguage),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.recAppBarSubtitle(reciter.name, appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: HomeBackdrop(
        child: surahsAsync.when(
          data: (surahs) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeroCard(
                    context,
                    reciter: reciter,
                    colorScheme: colorScheme,
                    savedCount: savedCount,
                    allSaved: allSaved,
                    bulk: bulk,
                    otherRecitersWithData: otherRecitersWithData,
                    appLanguage: appLanguage,
                  ),
                ),
                if (_totalBytes > 0 || _allReciterStorage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildPhoneStorageSection(
                      context,
                      colorScheme,
                      reciter,
                      appLanguage,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(
                      AppLocalizations.getRecitationText(
                        'surahs_section',
                        appLanguage,
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    final isComplete = downloads.isComplete(reciter.id, surah.id);
                    final progress = downloads.progressFor(reciter.id, surah.id);
                    final isLast = index == surahs.length - 1;

                    return _SurahDownloadRow(
                      surahId: surah.id,
                      surahName: surah.englishName,
                      isComplete: isComplete,
                      progress: progress,
                      isLast: isLast,
                      colorScheme: colorScheme,
                      appLanguage: appLanguage,
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
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(AppLocalizations.recError(e, appLanguage))),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required Reciter reciter,
    required ColorScheme colorScheme,
    required int savedCount,
    required bool allSaved,
    required BulkDownloadProgress? bulk,
    required int otherRecitersWithData,
    required String appLanguage,
  }) {
    final showTotalAllReciters =
        !_storageLoading && _totalBytes > 0 && otherRecitersWithData > 0;
    final totalSurahs = AudioOfflinePrompts.totalSurahs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.getRecitationText(
                            'selected_reciter_label',
                            appLanguage,
                          ),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reciter.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!_storageLoading)
                    _HeaderStatChip(
                      label: '$savedCount/$totalSurahs',
                      colorScheme: colorScheme,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_storageLoading)
                const LinearProgressIndicator(minHeight: 2)
              else ...[
                Text(
                  AppLocalizations.recHeroStorageLine(
                    savedCount,
                    totalSurahs,
                    _formatBytes(_currentReciterBytes),
                    appLanguage,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (showTotalAllReciters) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.recTotalAllReciters(
                      _formatBytes(_totalBytes),
                      appLanguage,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
              if (bulk != null) ...[
                const SizedBox(height: 12),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (!allSaved) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: bulk != null
                      ? OutlinedButton(
                          onPressed: () => ref
                              .read(audioDownloadProvider.notifier)
                              .cancelBulkDownload(),
                          child: Text(
                            AppLocalizations.getRecitationText(
                              'cancel_save_all',
                              appLanguage,
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () => ref
                              .read(audioDownloadProvider.notifier)
                              .downloadAllSurahs(reciter),
                          icon: const Icon(Icons.download_for_offline),
                          label: Text(
                            AppLocalizations.getRecitationText(
                              'save_all_114',
                              appLanguage,
                            ),
                          ),
                        ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.getRecitationText(
                          'all_surahs_saved',
                          appLanguage,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              if (!_storageLoading && _currentReciterBytes > 0) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: bulk != null
                        ? null
                        : () => _deleteReciter(reciter.id, reciter.name),
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    label: Text(
                      AppLocalizations.recDeleteAllAudioForReciter(
                        reciter.name,
                        appLanguage,
                      ),
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.getRecitationText('storage_on_phone', appLanguage),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: ListTile(
                  dense: true,
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
                          tooltip: AppLocalizations.getRecitationText(
                            'delete',
                            appLanguage,
                          ),
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
      parts.add('${summary.savedSurahCount}/114');
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
      return _CircleActionButton(
        colorScheme: colorScheme,
        icon: Icons.delete_outline,
        iconColor: colorScheme.error,
        tooltip: AppLocalizations.getRecitationText('delete', appLanguage),
        onPressed: () async {
          await ref.read(audioDownloadProvider.notifier).deleteSurah(reciterId, surahId);
          await _refreshStorage();
        },
      );
    }

    final reciter = ref.read(reciterProvider);
    return _CircleActionButton(
      colorScheme: colorScheme,
      icon: progress?.failed == true ? Icons.refresh : Icons.download_outlined,
      iconColor: colorScheme.primary,
      tooltip: AppLocalizations.getRecitationText('save', appLanguage),
      onPressed: () {
        ref.read(audioDownloadProvider.notifier).downloadSurah(reciter, surahId);
      },
    );
  }
}

class _SurahDownloadRow extends StatelessWidget {
  const _SurahDownloadRow({
    required this.surahId,
    required this.surahName,
    required this.isComplete,
    required this.progress,
    required this.isLast,
    required this.colorScheme,
    required this.appLanguage,
    required this.trailing,
  });

  final int surahId;
  final String surahName;
  final bool isComplete;
  final DownloadProgress? progress;
  final bool isLast;
  final ColorScheme colorScheme;
  final String appLanguage;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final subtitle = progress != null
        ? progress!.failed
            ? AppLocalizations.getRecitationText('failed_retry', appLanguage)
            : AppLocalizations.recDownloadingProgress(
                progress!.done,
                progress!.total,
                appLanguage,
              )
        : AppLocalizations.getRecitationText(
            isComplete ? 'saved_on_device' : 'not_saved',
            appLanguage,
          );
    final subtitleColor = progress?.failed == true
        ? colorScheme.error
        : isComplete
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(
                  '$surahId',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.colorScheme,
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onPressed,
  });

  final ColorScheme colorScheme;
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, size: 20, color: iconColor),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  const _HeaderStatChip({
    required this.label,
    required this.colorScheme,
  });

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
        ),
      ),
    );
  }
}
