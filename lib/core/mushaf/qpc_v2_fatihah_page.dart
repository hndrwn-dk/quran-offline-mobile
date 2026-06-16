import 'dart:convert';

import 'package:flutter/services.dart';

/// One word on a Madinah Mushaf line (QPC V2 glyph + Unicode fallback).
class QpcV2MushafWord {
  const QpcV2MushafWord({
    required this.codeV2,
    required this.textQpcHafs,
    required this.charType,
    required this.verseKey,
  });

  final String codeV2;
  final String textQpcHafs;
  final String charType;
  final String verseKey;

  factory QpcV2MushafWord.fromJson(Map<String, dynamic> json) {
    return QpcV2MushafWord(
      codeV2: json['code_v2'] as String,
      textQpcHafs: json['text_qpc_hafs'] as String,
      charType: json['char_type'] as String,
      verseKey: json['verse_key'] as String,
    );
  }
}

/// A single line in bundled QPC V2 sample page data.
class QpcV2MushafLine {
  const QpcV2MushafLine({
    required this.lineNumber,
    required this.pageNumber,
    required this.lineType,
    required this.centered,
    this.surahId,
    this.words = const [],
  });

  final int lineNumber;
  final int pageNumber;
  final String lineType;
  final bool centered;
  final int? surahId;
  final List<QpcV2MushafWord> words;

  bool get isSurahName => lineType == 'surah_name';

  bool get isAyah => lineType == 'ayah';

  String get glyphText => words.map((w) => w.codeV2).join();

  String get unicodeText => words.map((w) => w.textQpcHafs).join(' ');

  factory QpcV2MushafLine.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>? ?? const [];
    return QpcV2MushafLine(
      lineNumber: json['line_number'] as int,
      pageNumber: json['page_number'] as int? ?? 1,
      lineType: json['line_type'] as String,
      centered: json['centered'] as bool? ?? true,
      surahId: json['surah_id'] as int?,
      words: rawWords
          .map((e) => QpcV2MushafWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Bundled QPC V2 sample layout for comparison screens.
class QpcV2SamplePage {
  const QpcV2SamplePage({
    required this.pageNumber,
    required this.chapterId,
    required this.range,
    required this.lines,
    required this.source,
  });

  final int pageNumber;
  final int chapterId;
  final String range;
  final List<QpcV2MushafLine> lines;
  final String source;

  factory QpcV2SamplePage.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>;
    return QpcV2SamplePage(
      pageNumber: json['page_number'] as int,
      chapterId: json['chapter_id'] as int? ?? 1,
      range: json['range'] as String? ?? '',
      source: json['source'] as String? ?? '',
      lines: rawLines
          .map((e) => QpcV2MushafLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<QpcV2SamplePage> loadAliImran1To9() async {
    final raw = await rootBundle.loadString(
      'assets/mushaf/qpc_v2_ali_imran_1_9_page50.json',
    );
    return QpcV2SamplePage.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
