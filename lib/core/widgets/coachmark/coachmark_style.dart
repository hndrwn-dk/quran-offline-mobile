import 'package:flutter/material.dart';
import 'package:quran_offline/core/constants/app_colors.dart';

/// Visual tokens for coachmark overlays, aligned with Beranda sage/cream theme.
abstract final class CoachmarkStyle {
  static const Color overlay = Color(0x8C141A12);
  static const Color tooltipBackground = Color(0xFF2F3B2B);
  static const Color tooltipInk = Color(0xFFF6F8F1);
  static const Color tooltipBody = Color(0xFFD9DED1);
  static const Color tooltipDismiss = Color(0xFFB9C2AB);
  static const Color pulseRing = AppColors.warmPrimaryLight;

  static const double tooltipWidth = 250;
  static const double tooltipBorderRadius = 16;
  static const double spotlightPadding = 6;
  static const double spotlightBorderRadius = 12;
  static const Duration fadeDuration = Duration(milliseconds: 400);
  static const Duration tooltipDelay = Duration(milliseconds: 200);
  static const Duration pulseDuration = Duration(milliseconds: 2400);
}
