import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';

/// Page range definition from `index_pages.json`.
class PageRange {
  final int surahId;
  final int startAyah;
  final int endAyah;

  PageRange({
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
  });

  factory PageRange.fromJson(Map<String, dynamic> json) => PageRange(
        surahId: json['s'] as int,
        startAyah: json['a1'] as int,
        endAyah: json['a2'] as int,
      );
}

/// One visual block inside a Mushaf page.
///
/// This follows the spec in `Mushaf Mode.md`:
/// - One ayah = one visual block
/// - Optional surah header and Bismillah blocks
class MushafAyahBlock {
  final int? surahId;
  final int? ayahNo;
  final String text;
  final bool isSurahHeader;
  final bool isBismillah;

  const MushafAyahBlock({
    required this.text,
    this.surahId,
    this.ayahNo,
    this.isSurahHeader = false,
    this.isBismillah = false,
  });
}

/// Simple layout helper for Mushaf mode.
///
/// Key decisions:
/// - Ayah-based layout (no word-level measurement, no greedy breaking)
/// - Prefix ayah number (badge) – numbering taken directly from verse metadata
/// - No WidgetSpan / inline markers
class MushafLayout {
  /// Load ayah blocks for a given Mushaf page.
  static Future<List<MushafAyahBlock>> getPageBlocks(
    BuildContext context,
    int pageNo,
  ) async {
    final ranges = await _pageRanges(pageNo);
    if (ranges.isEmpty) return const [];

    final container = ProviderScope.containerOf(context, listen: false);
    final db = container.read(databaseProvider);
    final settings = container.read(settingsProvider);
    // Accessing settings keeps API similar, even though layout itself
    // does not depend on width/height anymore.
    // ignore: unused_local_variable
    final _ = settings.mushafFontSize;

    // Load surah display names for headers.
    final surahNames = await _loadSurahNames();

    // Collect all verses that belong to this page.
    final verses = <Verse>[];
    for (final r in ranges) {
      final part = await db.getVersesByRange(r.surahId, r.startAyah, r.endAyah);
      verses.addAll(part);
    }

    if (verses.isEmpty) return const [];

    // Ensure verses are sorted correctly (surah ASC, ayah ASC).
    verses.sort((a, b) {
      if (a.surahId != b.surahId) {
        return a.surahId.compareTo(b.surahId);
      }
      return a.ayahNo.compareTo(b.ayahNo);
    });

    final blocks = <MushafAyahBlock>[];
    int? lastSurah;

    for (final v in verses) {
      final isNewSurah = v.surahId != lastSurah;
      if (isNewSurah) {
        lastSurah = v.surahId;

        // Surah header block (centered title)
        final surahTitle = surahNames[v.surahId] ?? 'سورة';
        blocks.add(
          MushafAyahBlock(
            surahId: v.surahId,
            text: surahTitle,
            isSurahHeader: true,
          ),
        );

        // Optional Bismillah line (except for Surah 1 & 9)
        if (v.surahId != 1 && v.surahId != 9) {
          blocks.add(
            const MushafAyahBlock(
              text: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
              isBismillah: true,
            ),
          );
        }
      }

      // One ayah = one visual block.
      // Do NOT split or measure at word level.
      blocks.add(
        MushafAyahBlock(
          surahId: v.surahId,
          ayahNo: v.ayahNo,
          text: v.arabic,
        ),
      );
    }

    return blocks;
  }

  /// Optional prewarm – just loads blocks once. No disk cache.
  static Future<void> prewarm(BuildContext context, int pageNo) async {
    if (pageNo < 1 || pageNo > 604) return;
    await getPageBlocks(context, pageNo);
  }

  static Future<Map<int, String>> _loadSurahNames() async {
    final data = await rootBundle.loadString('assets/quran/surah_names/manifest.json');
    final map = jsonDecode(data) as Map<String, dynamic>;
    final items = map['items'] as List<dynamic>;
    return {
      for (final item in items) item['id'] as int: item['display'] as String,
    };
  }

  static Future<List<PageRange>> _pageRanges(int pageNo) async {
    final data = await rootBundle.loadString('assets/quran/index_pages.json');
    final map = jsonDecode(data) as Map<String, dynamic>;
    final list = map['$pageNo'] as List<dynamic>?;
    if (list == null) return const [];
    return list.map((e) => PageRange.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get the first surah ID for a given page number.
  /// Returns null if page is invalid or has no ranges.
  static Future<int?> getSurahIdForPage(int pageNo) async {
    final ranges = await _pageRanges(pageNo);
    if (ranges.isEmpty) return null;
    return ranges.first.surahId;
  }

  /// Get all unique surah IDs for a given page number, sorted.
  /// Returns empty list if page is invalid or has no ranges.
  static Future<List<int>> getSurahIdsForPage(int pageNo) async {
    final ranges = await _pageRanges(pageNo);
    if (ranges.isEmpty) return const [];
    final surahIds = ranges.map((r) => r.surahId).toSet().toList();
    surahIds.sort();
    return surahIds;
  }

  /// Helper to convert Western digits to Arabic-Indic digits for badges.
  static String toArabicIndicDigits(String text) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return text.split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? arabicIndic[digit] : char;
    }).join();
  }
}
