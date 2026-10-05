import 'package:flutter/material.dart';

/// Existing sage/cream brand, structured as Coolors-style 5 + 60-30-10.
///
/// Coolors (documentation of current hexes, not a new palette):
/// https://coolors.co/2d3f30-e8ede3-5a7358-6f8870-b5c7b1
///
/// | Share | Role                         | Hex       |
/// |------:|------------------------------|-----------|
/// | 60%   | neutralInk (type on soft UI) | #2D3F30   |
/// | 60%   | neutralCream (Beranda wash)  | #E8EDE3   |
/// | 30%   | primary                      | #5A7358   |
/// | 30%   | primaryBright (dark primary) | #6F8870   |
/// | 10%   | accent (outline / soft chip) | #B5C7B1   |
///
/// Reader / Mushaf / Juz reading canvas keep Material [ColorScheme.surface]
/// from seed — cream is HomeBackdrop + containers only, not verse pages.
class AppColors {
  AppColors._();

  // --- Coolors 5 (60 / 30 / 10) ---
  static const Color neutralInk = Color(0xFF2D3F30);
  static const Color neutralCream = Color(0xFFE8EDE3);
  static const Color primary = Color(0xFF5A7358);
  static const Color primaryBright = Color(0xFF6F8870);
  static const Color accent = Color(0xFFB5C7B1);

  // --- Tints / shades of the five (not a second palette) ---
  static const Color primaryDeep = Color(0xFF4A5F4C);
  static const Color primaryContainer = Color(0xFFD6E4D2);
  static const Color neutralMist = Color(0xFFF3F6F0);
  static const Color neutralSageWash = Color(0xFFDFE8DB);
  static const Color secondaryMuted = Color(0xFF5C6B58);
  static const Color onSecondaryContainer = Color(0xFF3A4438);
  static const Color onPrimaryDark = Color(0xFF1A281C);
  static const Color neutralCreamLift = Color(0xFFF4F6F0);

  static const Color brandSeed = primary;

  /// Legacy names — prefer [primary] / [primaryBright] / [primaryDeep].
  static const Color warmPrimary = primary;
  static const Color warmPrimaryLight = primaryBright;
  static const Color warmPrimaryDark = primaryDeep;

  static ColorScheme lightColorScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: Brightness.light,
    );
    return base.copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: neutralInk,
      secondary: secondaryMuted,
      secondaryContainer: neutralCream,
      onSecondaryContainer: onSecondaryContainer,
      surfaceContainerLow: neutralMist,
      surfaceContainerHigh: neutralCream,
      surfaceContainerHighest: neutralSageWash,
      outline: primary.withValues(alpha: 0.38),
      outlineVariant: accent,
    );
  }

  static ColorScheme darkColorScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      primary: primaryBright,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryDeep,
      onPrimaryContainer: primaryContainer,
      outline: primaryBright.withValues(alpha: 0.45),
      outlineVariant: primaryBright.withValues(alpha: 0.28),
    );
  }
}
