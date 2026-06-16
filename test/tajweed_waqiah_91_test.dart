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

  test('56:91 idgham bila ghunnah tagged but rendered plain black', () {
    final raw = File('assets/quran/s056.json').readAsStringSync();
    final verses = jsonDecode(raw) as List<dynamic>;
    final tj = (verses.firstWhere((v) => v['a'] == 91) as Map)['tj'] as String;

    expect(tj, contains('idgham_wo_ghunnah'));
    expect(tj, isNot(contains('ikhfa')));

    final spans = spansForAyah(91);
    final idghamWoGhunnahColor = TajweedColors.colorForClassWithTheme(
      'idgham_wo_ghunnah',
      isDark: false,
      colorScheme: colorScheme,
      defaultColor: defaultColor,
    );
    expect(idghamWoGhunnahColor, defaultColor);

    final coloredIdghamSpans = spans.where(
      (s) =>
          ((s.text ?? '').contains('م') || (s.text ?? '').contains('ل')) &&
          s.style?.color != defaultColor &&
          s.style?.color != colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );
    expect(coloredIdghamSpans, isEmpty,
        reason: 'salamun laka idgham wo ghunnah stays black on quran.com');
  });

  test('ikhfa green differs from idgham ghunnah blue', () {
    final ikhfa = TajweedColors.colorForClassWithTheme(
      'ikhfa',
      isDark: false,
      colorScheme: colorScheme,
      defaultColor: defaultColor,
    );
    final idgham = TajweedColors.colorForClassWithTheme(
      'idgham_ghunnah',
      isDark: false,
      colorScheme: colorScheme,
      defaultColor: defaultColor,
    );
    expect(ikhfa, isNot(idgham));
    expect(ikhfa, const Color(0xFF2E7D32));
    expect(idgham, const Color(0xFF1976D2));
  });
}
