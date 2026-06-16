import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_colors.dart';
import 'package:quran_offline/core/tajweed/tajweed_html.dart';
import 'package:quran_offline/core/tajweed/tajweed_parser.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

void main() {
  test('Al-Waqiah 56:8 enriched tj renders tafkhim on sad', () {
    final raw = File('assets/quran/s056.json').readAsStringSync();
    final verses = jsonDecode(raw) as List<dynamic>;
    final ayah8 = verses.firstWhere((v) => v['a'] == 8) as Map<String, dynamic>;
    final tj = ayah8['tj'] as String;
    final prepared = TajweedHtml.prepareForParsing(tj);

    expect(prepared, contains('class=tafkhim'));
    expect(prepared, contains('madda_obligatory'));

    const colorScheme = ColorScheme.light();
    const defaultColor = Colors.black;
    Color colorForClass(String cls) => TajweedColors.colorForClassWithTheme(
          cls,
          isDark: false,
          colorScheme: colorScheme,
          defaultColor: defaultColor,
        );

    final baseStyle = TajweedText.arabicDisplayStyle(
      fontSize: 24,
      color: defaultColor,
    );

    final spans = TajweedParser.parseToSpansWithColorFn(
      tajweedHtml: prepared,
      baseStyle: baseStyle,
      colorForClass: colorForClass,
    );
    final merged = TajweedText.coalesceSpansForArabicLayout(
      spans,
      defaultStyle: baseStyle,
    );

    final tafkhimBlue = colorForClass('tafkhim');
    final hasTafkhim = merged.any(
      (s) => s.style?.color == tafkhimBlue && (s.text ?? '').contains('ص'),
    );
    expect(hasTafkhim, isTrue);
  });
}
