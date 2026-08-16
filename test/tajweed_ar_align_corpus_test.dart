import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_ar_aligner.dart';

void main() {
  test('report tajweed-ar align failures across 6236 verses', () {
    var total = 0;
    var withTj = 0;
    var failed = 0;
    final byReason = <String, int>{};
    final samples = <String>[];

    for (var s = 1; s <= 114; s++) {
      final path = 'assets/quran/s${s.toString().padLeft(3, '0')}.json';
      final verses = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
      for (final raw in verses) {
        total++;
        final v = raw as Map<String, dynamic>;
        final ar = v['ar'] as String? ?? '';
        final tj = v['tj'] as String?;
        if (tj == null || tj.isEmpty) continue;
        withTj++;
        final key = '${v['s']}:${v['a']}';
        final result = TajweedArAligner.align(
          arabic: ar,
          tajweedHtml: tj,
          verseKey: key,
        );
        if (result.ok) continue;
        failed++;
        final reason = (result.failureReason ?? 'unknown')
            .replaceAll(RegExp(r'ar\[\d+\]'), 'ar[*]')
            .replaceAll(RegExp(r'tj\[\d+\]'), 'tj[*]');
        byReason[reason] = (byReason[reason] ?? 0) + 1;
        if (samples.length < 30) {
          samples.add('$key ${result.failureReason}');
        }
      }
    }

    // ignore: avoid_print
    print('align corpus: total=$total withTj=$withTj failed=$failed ok=${withTj - failed}');
    final ranked = byReason.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in ranked.take(20)) {
      // ignore: avoid_print
      print('  ${e.value}  ${e.key}');
    }
    for (final s in samples) {
      // ignore: avoid_print
      print('  sample $s');
    }

    expect(total, 6236);
    expect(withTj, 6236);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
