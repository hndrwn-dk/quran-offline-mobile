import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/transliteration_provider.dart';
import 'package:quran_offline/core/share/verse_share_content.dart';

/// Shares a verse as plain text (Arabic, translation, Play Store URL).
class VerseShare {
  VerseShare._();

  static Future<void> share({
    required BuildContext context,
    required WidgetRef ref,
    required Verse verse,
    required String surahName,
    required AppSettings settings,
  }) async {
    final transliteration = await ref
        .read(transliterationRepositoryProvider)
        .getForAyah(verse.surahId, verse.ayahNo);

    final content = VerseShareContent.from(
      verse: verse,
      surahName: surahName,
      settings: settings,
      transliterationText: transliteration,
    );

    await Share.share(content.buildShareCaption());
  }
}
