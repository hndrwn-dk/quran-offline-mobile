import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/share/verse_share_content.dart';
import 'package:quran_offline/core/share/verse_share_sheet.dart';

/// Two-path verse share: card PNG (short/medium) or text-only (long ayah).
class VerseShare {
  VerseShare._();

  static Future<void> share({
    required BuildContext context,
    required Verse verse,
    required String surahName,
    required AppSettings settings,
  }) async {
    final content = VerseShareContent.from(
      verse: verse,
      surahName: surahName,
      settings: settings,
    );

    if (content.fitsShareCard) {
      await showVerseShareCardSheet(context, content: content);
    } else {
      await Share.share(content.buildShareCaption(includeArabicInText: true));
    }
  }
}
