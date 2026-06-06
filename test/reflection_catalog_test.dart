import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final maxAyah = <int, int>{};

  setUpAll(() {
    for (var s = 1; s <= 114; s++) {
      final path = 'assets/quran/s${s.toString().padLeft(3, '0')}.json';
      final list = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
      var max = 0;
      for (final item in list) {
        final a = (item as Map<String, dynamic>)['a'] as int;
        if (a > max) max = a;
      }
      maxAyah[s] = max;
    }
  });

  void validateCatalog(String path) {
    final catalog = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final entries = catalog['entries'] as List<dynamic>;
    final ids = <String>{};

    for (final raw in entries) {
      final entry = raw as Map<String, dynamic>;
      final id = entry['id'] as String;
      expect(ids.add(id), isTrue, reason: 'duplicate id $id in $path');

      for (final field in ['title', 'summary', 'reflection']) {
        final map = entry[field] as Map<String, dynamic>;
        for (final lang in ['id', 'en', 'zh', 'ja']) {
          expect(map[lang], isNotEmpty, reason: '$id missing $field.$lang');
        }
      }

      final refs = entry['ayahRefs'] as List<dynamic>;
      expect(refs, isNotEmpty);
      for (final refRaw in refs) {
        final ref = refRaw as Map<String, dynamic>;
        final surah = ref['surah'] as int;
        final from = ref['from'] as int;
        final to = (ref['to'] as int?) ?? from;
        expect(from, lessThanOrEqualTo(maxAyah[surah]!));
        expect(to, lessThanOrEqualTo(maxAyah[surah]!));
      }
    }
  }

  test('calendar lenses catalog is valid', () {
    validateCatalog('assets/reflection/calendar_lenses_catalog.json');
  });

  test('weekly rotation catalog is valid', () {
    validateCatalog('assets/reflection/weekly_rotation_catalog.json');
  });
}
