import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_colors.dart';
import 'package:quran_offline/core/tajweed/tajweed_html.dart';
import 'package:quran_offline/core/tajweed/tajweed_parser.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

void main() {
  const defaultColor = Colors.black;
  const colorScheme = ColorScheme.light();
  final baseStyle = TajweedText.arabicDisplayStyle(fontSize: 24, color: defaultColor);
  final ikhfaGreen = TajweedColors.colorForClassWithTheme(
    'ikhfa',
    isDark: false,
    colorScheme: colorScheme,
    defaultColor: defaultColor,
  );
  final idghamBlue = TajweedColors.colorForClassWithTheme(
    'idgham_ghunnah',
    isDark: false,
    colorScheme: colorScheme,
    defaultColor: defaultColor,
  );

  List<TextSpan> spansForAyah(int ayah) {
    final raw = File('assets/quran/s056.json').readAsStringSync();
    final verses = jsonDecode(raw) as List<dynamic>;
    final tj = (verses.firstWhere((v) => v['a'] == ayah) as Map)['tj'] as String;
    final prepared = TajweedHtml.prepareForParsing(tj);
    final spans = TajweedParser.parseToSpansWithColorFn(
      tajweedHtml: prepared,
      baseStyle: baseStyle,
      colorForClass: (cls) => TajweedColors.colorForClassWithTheme(
        cls,
        isDark: false,
        colorScheme: colorScheme,
        defaultColor: defaultColor,
      ),
      normalizeArabic: false,
    );
    return TajweedText.coalesceSpansForArabicLayout(spans, defaultStyle: baseStyle);
  }

  Color? colorOfLetter(List<TextSpan> spans, String letter) {
    for (final s in spans) {
      if ((s.text ?? '').contains(letter)) return s.style?.color;
    }
    return null;
  }

  test('56:92 in kana — nun green, kaf black', () {
    final spans = spansForAyah(92);
    expect(colorOfLetter(spans, 'ن'), ikhfaGreen);
    expect(colorOfLetter(spans, 'ك'), defaultColor);
  });

  test('56:93 fanuzulun min — lam black, mim green', () {
    final spans = spansForAyah(93);
    expect(colorOfLetter(spans, 'ل'), defaultColor);
    expect(colorOfLetter(spans, 'م'), idghamBlue);
  });
}
