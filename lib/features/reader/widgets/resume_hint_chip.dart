import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/last_read_resolve.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/resume_hint_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/startup/resume_boundary.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Calm, dismissible chip shown for a few seconds after a cold-start resume.
class ResumeHintChip extends ConsumerStatefulWidget {
  const ResumeHintChip({
    super.key,
    required this.hint,
    this.surahVerses,
  });

  final ResumeHint hint;

  /// Already-loaded surah verses from the reader, to avoid a duplicate query.
  final List<Verse>? surahVerses;

  @override
  ConsumerState<ResumeHintChip> createState() => _ResumeHintChipState();
}

class _ResumeHintChipState extends ConsumerState<ResumeHintChip> {
  static const Duration _visibleFor = Duration(seconds: 4);

  ResumeBoundary? _boundary;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBoundary();
    });
  }

  Future<void> _loadBoundary() async {
    final db = ref.read(databaseProvider);
    final hint = widget.hint;
    ResumeBoundary? boundary;

    if (hint.mode == ResumeHintMode.surah) {
      final surahId = hint.surahId;
      if (surahId != null) {
        final verses = widget.surahVerses ?? await db.getVersesBySurah(surahId);
        final index = indexOfTargetVerse(
          verses,
          ayahNo: hint.ayahNo ?? 1,
          surahId: surahId,
        );
        if (index != null) {
          final juzVerses = await db.getVersesByJuz(verses[index].juz);
          boundary = computeSurahResumeBoundary(
            surahVerses: verses,
            verseIndex: index,
            juzVerses: juzVerses,
          );
        }
      }
    } else {
      final pageNo = hint.pageNo;
      if (pageNo != null) {
        final pageVerses = await db.getVersesByPage(pageNo);
        if (pageVerses.isNotEmpty) {
          final juzVerses = await db.getVersesByJuz(pageVerses.first.juz);
          boundary = computePageResumeBoundary(
            pageNo: pageNo,
            juzVerses: juzVerses,
          );
        }
      }
    }

    if (!mounted || boundary == null) return;
    setState(() => _boundary = boundary);
    _timer = Timer(_visibleFor, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _boundary = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boundary = _boundary;
    if (boundary == null) return const SizedBox.shrink();

    final language = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppLocalizations.formatResumeHint(
                  language: language,
                  kind: boundary.kind,
                  remaining: boundary.remaining,
                  juzNo: boundary.juzNo,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: colorScheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: _dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
