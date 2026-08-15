import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';

void main() {
  group('qpcV2GlyphLineAlign', () {
    test('centered layout lines stay centered', () {
      expect(qpcV2GlyphLineAlign(isCentered: true), TextAlign.center);
    });

    test('ayah lines use RTL start so Flutter justify cannot clip end words', () {
      expect(qpcV2GlyphLineAlign(isCentered: false), TextAlign.start);
      expect(qpcV2GlyphLineAlign(isCentered: false), isNot(TextAlign.justify));
    });
  });
}
