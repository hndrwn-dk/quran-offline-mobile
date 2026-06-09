import 'package:flutter/material.dart';

/// Decorative surah title using QUL Surah name font v2 ligatures.
class SurahNameGlyph extends StatelessWidget {
  const SurahNameGlyph({
    super.key,
    required this.surahId,
    this.fontSize = 44,
    this.color,
    this.textAlign = TextAlign.center,
  });

  final int surahId;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  static String ligatureFor(int surahId) {
    return 'surah${surahId.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurface;

    return Text(
      ligatureFor(surahId),
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: 'SurahNameV2',
        fontSize: fontSize,
        height: 1.1,
        color: fg,
      ),
    );
  }
}

/// Right-aligned QUL surah glyph for Surah/Juz/Page list rows.
class SurahNameListGlyph extends StatelessWidget {
  const SurahNameListGlyph({
    super.key,
    required this.surahId,
    this.fontSize = 26,
    this.color,
  });

  final int surahId;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SurahNameGlyph(
      surahId: surahId,
      fontSize: fontSize,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      textAlign: TextAlign.right,
    );
  }
}
