import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_ar_aligner.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

Map<String, dynamic> _verse(int surah, int ayah) {
  final file = File(
    'assets/quran/s${surah.toString().padLeft(3, '0')}.json',
  );
  final verses = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return verses.firstWhere((v) => (v as Map)['a'] == ayah) as Map<String, dynamic>;
}

void main() {
  test('1:6 paints ar letters, not U+0672 from tj', () {
    final v = _verse(1, 6);
    final ar = v['ar'] as String;
    final tj = v['tj'] as String?;
    if (tj == null) {
      markTestSkipped('bundled JSON omits tj until tajweed fetch');
      return;
    }
    final result = TajweedArAligner.align(arabic: ar, tajweedHtml: tj);
    expect(result.ok, isTrue, reason: result.failureReason);
    expect(result.paintedText, ar);
    expect(result.paintedText, isNot(contains('\u0672')));
    expect(result.paintedText, contains('\u0670'));
    expect(result.paintedText, isNot(contains('\u25cc')));
    expect(result.runs.any((r) => r.tajweedClass == 'madda_normal'), isTrue);
  });

  test('6:44 paints ar including dagger alif, never raw tj wavy hamza', () {
    final v = _verse(6, 44);
    final ar = v['ar'] as String;
    final tj = v['tj'] as String?;
    if (tj == null) {
      markTestSkipped('bundled JSON omits tj until tajweed fetch');
      return;
    }
    final result = TajweedArAligner.align(arabic: ar, tajweedHtml: tj);
    expect(result.ok, isTrue, reason: result.failureReason);
    expect(result.paintedText, ar);
    expect(result.paintedText, isNot(contains('\u0672')));
    expect(result.paintedText, contains('\u0670'));
    expect(result.paintedText, isNot(contains('\u25cc')));
    expect(result.runs.any((r) => r.tajweedClass == 'madda_normal'), isTrue);
  });

  test('align failure keeps ar and does not use tj letters', () {
    const ar = 'ٱهْدِنَا';
    const tj = '<tajweed class=madda_normal>XYZ</tajweed>';
    final result = TajweedArAligner.align(arabic: ar, tajweedHtml: tj);
    expect(result.ok, isFalse);
    expect(result.paintedText, ar);
    expect(result.runs, isEmpty);
    expect(result.failureReason, isNotNull);
  });

  test('U+06DF and U+06E0 are not treated as the same mark', () {
    const ar = 'أَنَا\u06df';
    const tj = 'أَنَا\u06e0';
    final result = TajweedArAligner.align(arabic: ar, tajweedHtml: tj);
    expect(result.ok, isFalse);
    expect(result.paintedText, ar);
  });

  testWidgets('TajweedText uses ar when alignment fails, not tj', (tester) async {
    const ar = 'بِسْمِ';
    const tj = '<tajweed class=madda_normal>XXXX</tajweed>';
    await tester.pumpWidget(
      MaterialApp(
        home: TajweedText(
          tajweedHtml: tj,
          arabicLetters: ar,
          fontSize: 22,
          defaultColor: Colors.black,
        ),
      ),
    );
    expect(find.text(ar), findsOneWidget);
    expect(find.textContaining('XXXX'), findsNothing);
  });

  testWidgets('aligned 1:6 madda span is not default black', (tester) async {
    final v = _verse(1, 6);
    final tj = v['tj'] as String?;
    if (tj == null) {
      markTestSkipped('bundled JSON omits tj until tajweed fetch');
      return;
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            final spans = TajweedArAligner.spansFor(
              context: context,
              arabic: v['ar'] as String,
              tajweedHtml: tj,
              baseStyle: TajweedText.arabicDisplayStyle(
                fontSize: 24,
                color: Colors.black,
              ),
              defaultColor: Colors.black,
            );
            final colored = spans.where(
              (s) =>
                  s.style?.color != null &&
                  s.style!.color != Colors.black,
            );
            expect(colored, isNotEmpty);
            final joined = spans.map((s) => s.text).join();
            expect(joined, v['ar']);
            expect(joined, isNot(contains('\u25cc')));
            expect(joined, isNot(contains('\u0672')));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
