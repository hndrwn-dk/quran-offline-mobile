import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/bookmark_open_context.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

/// Opens a bookmark in Surah reader or Mushaf based on where it was created.
Future<void> openBookmarkLocation(
  BuildContext context,
  WidgetRef ref,
  Bookmark bookmark,
) async {
  final openContext = bookmark.openContext;

  if (openContext == BookmarkOpenContext.mushaf) {
    final db = ref.read(databaseProvider);
    final pageNo =
        await db.getPageForAyah(bookmark.surahId, bookmark.ayahNo);
    if (!context.mounted) return;

    if (pageNo != null) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => MushafPageView(
            initialPage: pageNo,
            targetSurahId: bookmark.surahId,
            targetAyahNo: bookmark.ayahNo,
          ),
        ),
      );
      return;
    }
  }

  ref.read(readerSourceProvider.notifier).state = SurahSource(
    bookmark.surahId,
    targetAyahNo: bookmark.ayahNo,
  );
  ref.read(targetAyahProvider.notifier).state = bookmark.ayahNo;
  await openReaderScreen(context, ref);
}
