import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/resume_hint_provider.dart';
import 'package:quran_offline/core/reading/reading_completion.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

/// Opens the start of the unit after a completed one, or the start of the
/// Qur'an after khatam.
Future<void> openNextReadTarget(
  BuildContext context,
  WidgetRef ref,
  ReadingCompletion completion,
) async {
  final target = nextReadTarget(completion);

  if (target.pageNo != null) {
    ref.read(resumeHintProvider.notifier).state =
        ResumeHint.page(pageNo: target.pageNo!);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MushafPageView(initialPage: target.pageNo!),
      ),
    );
    return;
  }

  final source = target.source;
  if (source is SurahSource) {
    ref.read(resumeHintProvider.notifier).state = ResumeHint.surah(
      surahId: source.surahId,
      ayahNo: target.targetAyahNo ?? 1,
    );
  } else if (source is JuzSource) {
    ref.read(resumeHintProvider.notifier).state = ResumeHint.juz(
      juzNo: source.juzNo,
      surahId: target.targetSurahId,
      ayahNo: target.targetAyahNo,
    );
  } else {
    ref.read(resumeHintProvider.notifier).state = null;
  }

  ref.read(readerSourceProvider.notifier).state = source;
  ref.read(targetAyahProvider.notifier).state = target.targetAyahNo;
  ref.read(targetSurahIdProvider.notifier).state = target.targetSurahId;
  await openReaderScreen(context, ref);
}
