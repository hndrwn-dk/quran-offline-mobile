import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';

/// Structural 60-30-10 lock for the *existing* sage/cream brand.
/// Hex must not drift; Reader/Mushaf keep Material [ColorScheme.surface].
void main() {
  Color hex(String rgb) => Color(int.parse('FF$rgb', radix: 16));

  test('Coolors-style five swatches match existing brand hexes', () {
    expect(AppColors.neutralInk, hex('2D3F30'));
    expect(AppColors.neutralCream, hex('E8EDE3'));
    expect(AppColors.primary, hex('5A7358'));
    expect(AppColors.primaryBright, hex('6F8870'));
    expect(AppColors.accent, hex('B5C7B1'));
  });

  test('legacy warmPrimary aliases stay on the same hexes', () {
    expect(AppColors.warmPrimary, AppColors.primary);
    expect(AppColors.warmPrimaryLight, AppColors.primaryBright);
    expect(AppColors.warmPrimaryDark, hex('4A5F4C'));
    expect(AppColors.brandSeed, AppColors.primary);
  });

  test('light ColorScheme keeps reading surface off cream wash', () {
    final s = AppColors.lightColorScheme();
    expect(s.brightness, Brightness.light);
    expect(s.primary, AppColors.primary);
    expect(s.primaryContainer, hex('D6E4D2'));
    expect(s.onPrimaryContainer, AppColors.neutralInk);
    expect(s.secondaryContainer, AppColors.neutralCream);
    expect(s.surfaceContainerLow, hex('F3F6F0'));
    expect(s.surfaceContainerHigh, AppColors.neutralCream);
    expect(s.surfaceContainerHighest, hex('DFE8DB'));
    expect(s.outlineVariant, AppColors.accent);
    // Cream is HomeBackdrop / containers only — not the verse/Mushaf canvas.
    expect(s.surface, isNot(AppColors.neutralCream));
  });

  test('dark ColorScheme keeps existing primary mapping', () {
    final s = AppColors.darkColorScheme();
    expect(s.brightness, Brightness.dark);
    expect(s.primary, AppColors.primaryBright);
    expect(s.primaryContainer, AppColors.warmPrimaryDark);
    expect(s.onPrimary, hex('1A281C'));
    expect(s.onPrimaryContainer, hex('D6E4D2'));
  });
}
