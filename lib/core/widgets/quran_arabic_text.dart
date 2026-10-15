import 'package:flutter/material.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';

/// Renders Quran Arabic (`ar`) codepoint-for-codepoint.
///
/// Default face is Digital Khatt V2 (Reader, Explore, share, library, etc.).
/// Mushaf keeps its own Uthmanic / QPC V2 widgets and does not use this.
/// No letter rewriting, no span coalescing, no sukun substitution.
class QuranArabicText extends StatelessWidget {
  final String arabic;
  final double fontSize;
  final Color defaultColor;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final double height;
  final bool selectable;
  /// Defaults to [QuranFonts.digitalKhattV2]. Pass [QuranFonts.uthmanicHafsV22]
  /// only when a non-Mushaf caller must keep the old Uthmanic face.
  final String? fontFamily;

  const QuranArabicText({
    super.key,
    required this.arabic,
    required this.fontSize,
    this.defaultColor = Colors.black,
    this.textDirection = TextDirection.rtl,
    this.textAlign = TextAlign.right,
    this.height = 1.7,
    this.selectable = true,
    this.fontFamily,
  });

  static TextStyle arabicDisplayStyle({
    required double fontSize,
    required Color color,
    double height = 1.7,
    bool isLightTheme = false,
    String? fontFamily,
  }) {
    final family = fontFamily ?? QuranFonts.digitalKhattV2;
    return TextStyle(
      fontSize: fontSize,
      fontFamily: family,
      fontFamilyFallback: family == QuranFonts.digitalKhattV2
          ? QuranFonts.digitalKhattFallbacks
          : QuranFonts.uthmanicFallbacks,
      height: height,
      color: color,
      locale: const Locale('ar'),
    );
  }

  TextStyle quranArabicStyle({
    double? fontSize,
    Color? color,
    double? height,
  }) {
    return arabicDisplayStyle(
      fontSize: fontSize ?? this.fontSize,
      color: color ?? defaultColor,
      height: height ?? this.height,
      fontFamily: fontFamily,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = quranArabicStyle();
    return Localizations.override(
      context: context,
      locale: const Locale('ar'),
      child: selectable
          ? SelectableText(
              arabic,
              style: style,
              textDirection: textDirection,
              textAlign: textAlign,
            )
          : Text(
              arabic,
              style: style,
              textDirection: textDirection,
              textAlign: textAlign,
            ),
    );
  }
}
