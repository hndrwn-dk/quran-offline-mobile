import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asmaul husna catalog has 99 unique entries and valid ayah ranges', () {
    final catalogFile = File('assets/asma/asmaul_husna_catalog.json');
    expect(catalogFile.existsSync(), isTrue);

    final catalog =
        jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
    final entries = catalog['entries'] as List<dynamic>;
    expect(entries.length, 99);

    final maxAyah = <int, int>{};
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

    final ids = <String>{};
    final numbers = <int>{};

    for (final raw in entries) {
      final entry = raw as Map<String, dynamic>;
      final id = entry['id'] as String;
      final number = entry['number'] as int;
      expect(ids.add(id), isTrue, reason: 'duplicate id $id');
      expect(numbers.add(number), isTrue, reason: 'duplicate number $number');
      expect(number, inInclusiveRange(1, 99));

      for (final field in ['title', 'summary', 'reflection']) {
        final map = entry[field] as Map<String, dynamic>;
        for (final lang in ['id', 'en', 'zh', 'ja']) {
          expect(map[lang], isNotEmpty, reason: '$id missing $field.$lang');
        }
      }

      expect(entry['arabic'], isNotEmpty);
      expect(entry['transliteration'], isNotEmpty);

      final refs = entry['ayahRefs'] as List<dynamic>;
      expect(refs, isNotEmpty);

      for (final refRaw in refs) {
        final ref = refRaw as Map<String, dynamic>;
        final surah = ref['surah'] as int;
        final from = ref['from'] as int;
        final to = (ref['to'] as int?) ?? from;

        expect(surah, inInclusiveRange(1, 114));
        expect(from, greaterThan(0));
        expect(to, greaterThanOrEqualTo(from));
        expect(maxAyah.containsKey(surah), isTrue);
        expect(from, lessThanOrEqualTo(maxAyah[surah]!));
        expect(to, lessThanOrEqualTo(maxAyah[surah]!));
      }
    }
  });
}
