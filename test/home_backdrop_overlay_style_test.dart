import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';

void main() {
  group('HomeBackdrop.overlayStyle', () {
    test('does not set bar colours deprecated by Android 15 edge-to-edge', () {
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: brightness,
        );
        final style = HomeBackdrop.overlayStyle(scheme);

        expect(style.statusBarColor, isNull);
        expect(style.systemNavigationBarColor, isNull);
        expect(style.systemNavigationBarDividerColor, isNull);
      }
    });

    test('keeps icon contrast so bars stay legible over the backdrop', () {
      final light = HomeBackdrop.overlayStyle(
        ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      );
      expect(light.statusBarIconBrightness, Brightness.dark);
      expect(light.statusBarBrightness, Brightness.light);

      final dark = HomeBackdrop.overlayStyle(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      );
      expect(dark.statusBarIconBrightness, Brightness.light);
      expect(dark.statusBarBrightness, Brightness.dark);
    });
  });
}
