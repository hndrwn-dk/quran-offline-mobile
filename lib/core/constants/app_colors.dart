import 'package:flutter/material.dart';

/// Brand greens — warmer sage, aligned with Beranda cream/sage cards.
class AppColors {
  AppColors._();

  static const Color brandSeed = Color(0xFF5A7358);

  static const Color warmPrimary = Color(0xFF5A7358);
  static const Color warmPrimaryLight = Color(0xFF6F8870);
  static const Color warmPrimaryDark = Color(0xFF4A5F4C);

  static const Color _lightPrimaryContainer = Color(0xFFD6E4D2);
  static const Color _lightOnPrimaryContainer = Color(0xFF2D3F30);
  static const Color _lightSurfaceContainerLow = Color(0xFFF3F6F0);
  static const Color _lightOutlineVariant = Color(0xFFB5C7B1);

  static ColorScheme lightColorScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: Brightness.light,
    );
    return base.copyWith(
      primary: warmPrimary,
      onPrimary: Colors.white,
      primaryContainer: _lightPrimaryContainer,
      onPrimaryContainer: _lightOnPrimaryContainer,
      secondary: const Color(0xFF5C6B58),
      secondaryContainer: const Color(0xFFE8EDE3),
      onSecondaryContainer: const Color(0xFF3A4438),
      surfaceContainerLow: _lightSurfaceContainerLow,
      surfaceContainerHigh: const Color(0xFFE8EDE3),
      surfaceContainerHighest: const Color(0xFFDFE8DB),
      outline: warmPrimary.withValues(alpha: 0.38),
      outlineVariant: _lightOutlineVariant,
    );
  }

  static ColorScheme darkColorScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      primary: warmPrimaryLight,
      onPrimary: const Color(0xFF1A281C),
      primaryContainer: warmPrimaryDark,
      onPrimaryContainer: _lightPrimaryContainer,
      outline: warmPrimaryLight.withValues(alpha: 0.45),
      outlineVariant: warmPrimaryLight.withValues(alpha: 0.28),
    );
  }
}
