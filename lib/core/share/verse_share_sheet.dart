import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_offline/core/share/verse_share_card.dart';
import 'package:quran_offline/core/share/verse_share_content.dart';
import 'package:quran_offline/core/share/widget_capture.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Modal preview + PNG capture (Ramadan-tracker style) for eligible verses.
Future<void> showVerseShareCardSheet(
  BuildContext context, {
  required VerseShareContent content,
}) async {
  final boundaryKey = GlobalKey();
  final lang = content.appLanguage;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: boundaryKey,
              child: VerseShareCard(content: content),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _shareFromSheet(
                dialogContext,
                boundaryKey: boundaryKey,
                content: content,
              ),
              icon: const Icon(Icons.share_outlined, size: 20),
              label: Text(AppLocalizations.getShareAction(lang)),
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 44),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _shareFromSheet(
  BuildContext dialogContext, {
  required GlobalKey boundaryKey,
  required VerseShareContent content,
}) async {
  await Future.delayed(const Duration(milliseconds: 80));

  final file = await captureRepaintBoundaryToPng(
    boundaryKey,
    filePrefix: 'ayah_${content.verse.surahId}_${content.verse.ayahNo}',
  );

  if (!dialogContext.mounted) return;

  if (file == null) {
    Navigator.pop(dialogContext);
    await _shareTextOnly(content);
    return;
  }

  try {
    // Image only — verse + Play link are already on the PNG; no duplicate caption.
    await Share.shareXFiles([XFile(file.path)]);
  } finally {
    await _deleteQuietly(file);
    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
  }
}

Future<void> _shareTextOnly(VerseShareContent content) async {
  await Share.share(content.buildShareCaption(includeArabicInText: true));
}

Future<void> _deleteQuietly(File file) async {
  try {
    await file.delete();
  } catch (_) {}
}
