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
  final baseStyle = TajweedText.arabicDisplayStyle(
    fontSize: 24,
    color: defaultColor,
  );
  final colorForClass = (String cls) => TajweedColors.colorForClassWithTheme(
        cls,
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
      colorForClass: colorForClass,
      normalizeArabic: false,
    );
    return TajweedText.coalesceSpansForArabicLayout(
      spans,
      defaultStyle: baseStyle,
    );
  }

  Color? colorOfLetter(List<TextSpan> spans, String letter) {
    for (final s in spans) {
      final text = s.text ?? '';
      if (text.contains(letter)) return s.style?.color;
    }
    return null;
  }

  test('56:95 حقّ qaf is tafkhim blue, yaqeen qaf not whole-word blue', () {
    final spans = spansForAyah(95);
    final haqqColor = colorOfLetter(spans, 'ق');
    expect(haqqColor, colorForClass('tafkhim'));

    final blue = colorForClass('tafkhim');
    final yaqeenBlue = spans.where(
      (s) =>
          (s.text ?? '').contains('يَق') &&
          s.style?.color == blue &&
          (s.text ?? '').contains('نِ'),
    );
    expect(yaqeenBlue, isEmpty);

    final maddYa = spans.where(
      (s) =>
          (s.text ?? '').contains('ي') &&
          s.style?.color == colorForClass('madda_permissible'),
    );
    expect(maddYa, isNotEmpty);
  });

  test('56:96 rabbika ra and azeem za are tafkhim blue', () {
    final spans = spansForAyah(96);
    expect(colorOfLetter(spans, 'ر'), colorForClass('tafkhim'));
    expect(colorOfLetter(spans, 'ظ'), colorForClass('tafkhim'));
  });

  test('56:93 min nun is not tafkhim blue', () {
    final spans = spansForAyah(93);
    final mimColor = colorOfLetter(spans, 'م');
    expect(mimColor, colorForClass('idgham_ghunnah'));
    final noonSpan = spans.where((s) => (s.text ?? '').contains('ن'));
    for (final s in noonSpan) {
      expect(s.style?.color, isNot(colorForClass('tafkhim')));
    }
  });

  test('56:94 sad is tafkhim blue', () {
    final spans = spansForAyah(94);
    expect(colorOfLetter(spans, 'ص'), colorForClass('tafkhim'));
  });
}
