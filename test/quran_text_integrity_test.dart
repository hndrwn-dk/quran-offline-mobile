import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';

String? _verseAr(int surah, int ayah) {
  final path =
      'assets/quran/s${surah.toString().padLeft(3, '0')}.json';
  final file = File(path);
  if (!file.existsSync()) return null;
  final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  for (final raw in list) {
    final map = raw as Map<String, dynamic>;
    if (map['a'] == ayah) return map['ar'] as String;
  }
  return null;
}

Iterable<String> _allArabic() sync* {
  for (var s = 1; s <= 114; s++) {
    final path = 'assets/quran/s${s.toString().padLeft(3, '0')}.json';
    final file = File(path);
    if (!file.existsSync()) continue;
    final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    for (final raw in list) {
      yield (raw as Map<String, dynamic>)['ar'] as String;
    }
  }
}

void main() {
  final s001 = File('assets/quran/s001.json');
  final skipMissing =
      s001.existsSync() ? null : 'assets/quran s001.json missing';

  test('corpus has no dotted-circle or wavy-hamza-alef; expected marks present', () {
    var count0670 = 0;
    var count0640 = 0;
    var count06D6 = 0;
    var count06DA = 0;
    var verses = 0;
    for (final ar in _allArabic()) {
      verses++;
      expect(ar.contains('\u25CC'), isFalse, reason: 'U+25CC in verse');
      expect(ar.contains('\u0672'), isFalse, reason: 'U+0672 in verse');
      for (final cp in ar.runes) {
        if (cp == 0x0670) count0670++;
        if (cp == 0x0640) count0640++;
        if (cp == 0x06D6) count06D6++;
        if (cp == 0x06DA) count06DA++;
      }
    }
    expect(verses, greaterThan(0));
    expect(count0670, greaterThan(0));
    expect(count0640, greaterThan(0));
    expect(count06D6, greaterThan(0));
    expect(count06DA, greaterThan(0));
  }, skip: skipMissing);

  test('golden ayahs load ar from assets', () {
    expect(_verseAr(1, 1), isNotNull);
    expect(_verseAr(1, 6), isNotNull);
    expect(_verseAr(2, 1), isNotNull);
    expect(_verseAr(6, 44), isNotNull);
    expect(_verseAr(1, 1)!.isNotEmpty, isTrue);
    expect(_verseAr(1, 6)!.contains('\u0672'), isFalse);
  }, skip: skipMissing);

  testWidgets('QuranArabicText 1:1 equals ar', (tester) async {
    final ar = _verseAr(1, 1)!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranArabicText(
            arabic: ar,
            fontSize: 24,
            defaultColor: Colors.black,
          ),
        ),
      ),
    );
    expect(find.text(ar), findsOneWidget);
  }, skip: skipMissing);
}
