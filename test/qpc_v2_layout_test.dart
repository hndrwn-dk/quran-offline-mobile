import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final layoutDb = File('assets/mushaf/layout/qpc_v2_15_lines.sqlite');
  final wordsDb = File('assets/mushaf/script/qpc_v2_words.sqlite');
  final pageFont = File('assets/fonts/qpc_v2/p1.ttf');

  test('QPC V2 mushaf assets exist on disk after sync', () {
    expect(layoutDb.existsSync(), isTrue, reason: layoutDb.path);
    expect(wordsDb.existsSync(), isTrue, reason: wordsDb.path);
    expect(pageFont.existsSync(), isTrue, reason: pageFont.path);
  });
}
