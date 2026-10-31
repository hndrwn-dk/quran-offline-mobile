import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MushafPageView(initialPage: target.pageNo!),
      ),
    );
    return;
  }

  ref.read(readerSourceProvider.notifier).state = target.source;
  ref.read(targetAyahProvider.notifier).state = target.targetAyahNo;
  ref.read(targetSurahIdProvider.notifier).state = target.targetSurahId;
  await openReaderScreen(context, ref);
}
