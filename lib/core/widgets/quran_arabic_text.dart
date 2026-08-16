import 'package:flutter/material.dart';

/// Renders Quran Arabic (`ar`) codepoint-for-codepoint.
///
/// No letter rewriting, no span coalescing, no sukun substitution.
class QuranArabicText extends StatelessWidget {
  final String arabic;
  final double fontSize;
  final Color defaultColor;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final double height;
  final bool selectable;

  const QuranArabicText({
    super.key,
    required this.arabic,
    required this.fontSize,
    this.defaultColor = Colors.black,
    this.textDirection = TextDirection.rtl,
    this.textAlign = TextAlign.right,
    this.height = 1.7,
    this.selectable = true,
  });

  static TextStyle arabicDisplayStyle({
    required double fontSize,
    required Color color,
    double height = 1.7,
    bool isLightTheme = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'UthmanicHafsV22',
      fontFamilyFallback: const [
        'UthmanicHafs',
        'KFGQPCUthmanic',
        'ScheherazadeNew',
      ],
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
