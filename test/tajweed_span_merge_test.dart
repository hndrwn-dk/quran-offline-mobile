import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

void main() {
  const defaultStyle = TextStyle(
    fontFamily: 'UthmanicHafsV22',
    fontSize: 24,
    color: Colors.black,
  );

  test('shouldMergeArabicSpans detects madda bridge before ba', () {
    expect(
      TajweedText.shouldMergeArabicSpans('وَأَصْحَـ', 'بُ'),
      isTrue,
      reason: 'tatweel madda must connect to following ba',
    );
  });

  test('shouldMergeArabicSpans detects single-letter laam split', () {
    expect(TajweedText.shouldMergeArabicSpans('\u0644', 'شِّمَالِ'), isTrue);
  });

  test('shouldMergeArabicSpans keeps word boundary at space', () {
    expect(TajweedText.shouldMergeArabicSpans('بُ ', 'ٱ'), isFalse);
    expect(TajweedText.shouldMergeArabicSpans('مَآ ', 'أَ'), isFalse);
  });

  test('coalesce merges ashabu word split like Al-Waqiah 56:9', () {
    final spans = <TextSpan>[
      const TextSpan(text: 'وَأَصْحَ'),
      const TextSpan(text: 'ـ'),
      const TextSpan(text: 'بُ '),
      const TextSpan(text: 'ٱ'),
      const TextSpan(text: 'لْمَشْــَٔمَةِ'),
    ];

    final merged = TajweedText.coalesceSpansForArabicLayout(
      spans,
      defaultStyle: defaultStyle,
    );

    final joined = merged.map((s) => s.text).join();
    expect(joined, contains('أَصْحَـبُ'));
    expect(
      merged.any((s) => (s.text ?? '') == 'بُ ' || (s.text ?? '') == 'بُ'),
      isFalse,
      reason: 'ba must not stay in an isolated span after حَـ',
    );
  });

  test('coalesce keeps laam shamsiyah color on lam only (56:41)', () {
    final coloredLam = TextStyle(
      fontFamily: 'UthmanicHafsV22',
      fontSize: 24,
      color: Colors.orange,
    );
    final spans = <TextSpan>[
      const TextSpan(text: 'وَأَصْحَـبُ '),
      const TextSpan(text: 'ٱ'),
      TextSpan(text: 'ل', style: coloredLam),
      const TextSpan(text: 'شِّمَالِ'),
    ];

    final merged = TajweedText.coalesceSpansForArabicLayout(
      spans,
      defaultStyle: defaultStyle,
    );

    final lamSpan = merged.firstWhere(
      (s) => (s.text ?? '').contains('ل'),
      orElse: () => const TextSpan(text: ''),
    );
    expect(lamSpan.style?.color, Colors.orange);
    final sheenSpan = merged.firstWhere(
      (s) => (s.text ?? '').contains('ش'),
      orElse: () => const TextSpan(text: ''),
    );
    expect(sheenSpan.style?.color ?? Colors.black, Colors.black);
  });
}
