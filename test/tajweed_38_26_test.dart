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
    fontSize: 20,
    color: defaultColor,
  );

  List<TextSpan> spansForVerse(String tj) {
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
    );
    return TajweedText.coalesceSpansForArabicLayout(
      spans,
      defaultStyle: baseStyle,
    );
  }

  test('ikhafa shafawi split keeps damma on meem (38:26 فَٱحْكُم)', () {
    const raw =
        'حْك<tajweed class=ikhafa_shafawi>ُم ب</tajweed>َيْنَ';
    final prepared = TajweedHtml.prepareForParsing(raw);
    expect(prepared, contains('<tajweed class=ikhafa_shafawi>ُم</tajweed>'));
    expect(prepared, isNot(contains('مم')));

    final spans = spansForVerse(raw);
    final joined = spans.map((s) => s.text).join();
    expect(joined, 'حْكُم بَيْنَ');
  });

  test('coalesced 38:26 tajweed text matches plain Arabic', () {
    final verses = jsonDecode(
      File('assets/quran/s038.json').readAsStringSync(),
    ) as List<dynamic>;
    final verse = verses.firstWhere((v) => (v as Map)['a'] == 26) as Map;
    final tj = verse['tj'] as String;
    final plain = TajweedHtml.plainArabicFromHtml(tj);

    final joined = spansForVerse(tj).map((s) => s.text).join().trim();
    final normalizedPlain =
        plain.replaceAll(RegExp(r'\s*٢٦\s*$'), '').trim();
    expect(joined, normalizedPlain);
    expect(joined, contains('فَاحْكُم بَيْنَ'));
    expect(joined, isNot(contains('مم')));
  });

  test('leading fatha after ikhafa tag attaches to ba in بَيْنَ', () {
    final spans = <TextSpan>[
      const TextSpan(text: 'حْك'),
      const TextSpan(
        text: 'ُم',
        style: TextStyle(color: Colors.green),
      ),
      const TextSpan(text: ' ب'),
      const TextSpan(text: 'َيْنَ'),
    ];

    final merged = TajweedText.mergeLeadingCombiningIntoPrevious(
      spans,
      defaultStyle: baseStyle,
    );

    expect(merged.map((s) => s.text).join(), 'حْكُم بَيْنَ');
    final baSpan = merged.firstWhere((s) => (s.text ?? '').contains('بَ'));
    expect(baSpan.style?.color, defaultColor);
  });
}
