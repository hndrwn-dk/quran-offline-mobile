import 'package:flutter/material.dart';

/// Tajweed colors aligned with Quran.com / Dar Al-Marifa legend.
///
/// Legend (quran.com): grey silent · yellow/orange/red madd · green ghunnah/ikhfa
/// · light blue qalqalah · dark blue tafkhim · idgham with ghunnah uses blue.
/// Idgham without ghunnah is tagged in API data but rendered plain (black).
class TajweedColors {
  TajweedColors._();

  static String normalizeClass(String raw) {
    final c = raw.trim().toLowerCase();
    return switch (c) {
      'ikhafa' => 'ikhfa',
      'qalaqah' => 'qalqalah',
      'slnt' => 'silent',
      _ => c,
    };
  }

  static Color colorForClass(
    String tajweedClass,
    BuildContext context, {
    Color? defaultColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return colorForClassWithTheme(
      normalizeClass(tajweedClass),
      isDark: isDark,
      colorScheme: colorScheme,
      defaultColor: defaultColor ??
          (isDark ? Colors.white : Colors.black),
    );
  }

  static Color colorForClassWithTheme(
    String tajweedClass, {
    required bool isDark,
    required ColorScheme colorScheme,
    required Color defaultColor,
  }) {
    return switch (tajweedClass) {
      // Grey — hamzah wasl, silent letters
      'ham_wasl' ||
      'silent' ||
      'custom-alef-maksora' =>
        colorScheme.onSurfaceVariant.withValues(alpha: 0.55),

      // Yellow — normal madd (2 counts)
      'madda_normal' => isDark
          ? const Color(0xFFFFD54F)
          : const Color(0xFFC9A227),

      // Amber — permissible madd (2/4/6)
      'madda_permissible' => isDark
          ? const Color(0xFFFFB74D)
          : const Color(0xFFE8A317),

      // Orange — separated obligatory madd (2/4/6)
      'madda_obligatory_monfasel' || 'madda_obligatory' => isDark
          ? const Color(0xFFFF8A65)
          : const Color(0xFFE67E22),

      // Red — connected obligatory madd (4/5)
      'madda_obligatory_mottasel' => isDark
          ? const Color(0xFFEF5350)
          : const Color(0xFFD32F2F),

      // Dark red — necessary madd (6 counts)
      'madda_necessary' => isDark
          ? const Color(0xFFE53935)
          : const Color(0xFFB71C1C),

      // Green — ghunnah / ikhfa (quran.com legend)
      'ikhfa' || 'ikhafa_shafawi' || 'ghunnah' || 'iqlab' => isDark
          ? const Color(0xFF81C784)
          : const Color(0xFF2E7D32),

      // Blue — idgham with ghunnah (and rare idgham subtypes)
      'idgham' ||
      'idgham_ghunnah' ||
      'idgham_shafawi' ||
      'idgham_mutajanisayn' ||
      'idgham_mutaqaribayn' => isDark
          ? const Color(0xFF64B5F6)
          : const Color(0xFF1976D2),

      // Plain — idgham without ghunnah (tagged in API, black on quran.com)
      'idgham_wo_ghunnah' => defaultColor,

      // Light blue — qalqalah
      'qalqalah' => isDark
          ? const Color(0xFF4FC3F7)
          : const Color(0xFF29B6F6),

      // Dark blue — tafkhim (heavy letters)
      'tafkhim' => isDark
          ? const Color(0xFF1565C0)
          : const Color(0xFF0D47A1),

      // Yellow — solar lam
      'laam_shamsiyah' => isDark
          ? const Color(0xFFFFD54F)
          : const Color(0xFFF9A825),

      _ => defaultColor,
    };
  }

  /// Colors for the settings tajweed guide (light-theme baseline).
  static Color guideColor(String ruleKey, ColorScheme colorScheme) {
    return colorForClassWithTheme(
      normalizeClass(ruleKey),
      isDark: false,
      colorScheme: colorScheme,
      defaultColor: colorScheme.onSurface,
    );
  }
}
