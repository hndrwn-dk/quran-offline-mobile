import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/id_query_normalizer.dart';

void main() {
  final vectorsFile = File('tool/fixtures/id_normalizer_vectors.json');

  test('normalizerVersion is 1', () {
    expect(IdQueryNormalizer.normalizerVersion, 1);
  });

  test('shared vectors match Python suite', () {
    expect(vectorsFile.existsSync(), isTrue);
    final cases = jsonDecode(vectorsFile.readAsStringSync()) as List<dynamic>;
    expect(cases, isNotEmpty);
    for (final raw in cases) {
      final caseMap = raw as Map<String, dynamic>;
      final input = caseMap['in'] as String;
      final expected = caseMap['out'] as String;
      expect(
        IdQueryNormalizer.normalize(input),
        expected,
        reason: 'in=$input',
      );
    }
    expect(cases.length, 13);
  });

  test('empty string', () {
    expect(IdQueryNormalizer.normalize(''), '');
    expect(IdQueryNormalizer.normalize('   '), '');
  });

  test('min stem length 3', () {
    expect(IdQueryNormalizer.normalize('dia'), 'dia');
    expect(IdQueryNormalizer.normalize('ani'), 'ani');
  });

  test('prefix and suffix together', () {
    expect(IdQueryNormalizer.normalize('dikerjakan'), 'kerja');
    expect(IdQueryNormalizer.normalize('pekerjaannya'), 'kerja');
  });
}
