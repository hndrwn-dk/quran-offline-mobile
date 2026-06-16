import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_colors.dart';
import 'package:quran_offline/core/tajweed/tajweed_html.dart';
import 'package:quran_offline/core/tajweed/tajweed_parser.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

/// Verifies the shared tajweed pipeline handles every bundled verse.
void main() {
  const defaultColor = Colors.black;
  const colorScheme = ColorScheme.light();
  final baseStyle = TajweedText.arabicDisplayStyle(
    fontSize: 20,
    color: defaultColor,
  );
  final colorForClass = (String cls) => TajweedColors.colorForClassWithTheme(
        cls,
        isDark: false,
        colorScheme: colorScheme,
        defaultColor: defaultColor,
      );

  test('prepareForParsing succeeds for all 6236 verses', () {
    var count = 0;
    for (var surah = 1; surah <= 114; surah++) {
      final path =
          'assets/quran/s${surah.toString().padLeft(3, '0')}.json';
      final verses = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
      for (final raw in verses) {
        final verse = raw as Map<String, dynamic>;
        final tj = verse['tj'] as String?;
        expect(tj, isNotNull, reason: '${verse['s']}:${verse['a']} missing tj');
        expect(tj, isNotEmpty);
        final prepared = TajweedHtml.prepareForParsing(tj!);
        expect(prepared, isNotEmpty);
        final spans = TajweedParser.parseToSpansWithColorFn(
          tajweedHtml: prepared,
          baseStyle: baseStyle,
          colorForClass: colorForClass,
          normalizeArabic: false,
        );
        TajweedText.coalesceSpansForArabicLayout(
          spans,
          defaultStyle: baseStyle,
        );
        count++;
      }
    }
    expect(count, 6236);
  });
}
