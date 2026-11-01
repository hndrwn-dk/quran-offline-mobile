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

/// Compact left-aligned QUL glyph for search result rows.
class SurahNameSearchGlyph extends StatelessWidget {
  const SurahNameSearchGlyph({super.key, required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context) {
    return SurahNameGlyph(
      surahId: surahId,
      fontSize: 22,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      textAlign: TextAlign.left,
    );
  }
}

/// Centered decorative QUL glyph for Mushaf page surah headers.
///
/// The glyph is fitted inside a slot constrained by BOTH its width and its
/// height, and never clipped: a wide banner shrinks to the slot width, a tall
/// one to the slot height. [maxHeight] caps the slot so a short ligature can
/// never grow past the page row it belongs to.
class SurahNameMushafGlyph extends StatelessWidget {
  const SurahNameMushafGlyph({
    super.key,
    required this.surahId,
    required this.mushafFontSize,
    this.slotWidthFactor = 0.5,
    this.maxHeight,
    this.verticalPadding = 14,
  });

  final int surahId;
  final double mushafFontSize;

  /// Share of the page width the banner may use.
  final double slotWidthFactor;

  /// Hard height cap in logical pixels (defaults to the legacy 44–54 slot).
  final double? maxHeight;

  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width - 32;
          final slotWidth = contentWidth * slotWidthFactor;
          final slotHeight =
              maxHeight ?? (mushafFontSize * 1.55).clamp(44.0, 54.0);

          return Center(
            child: SizedBox(
              width: slotWidth,
              height: slotHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SurahNameGlyph(
                  surahId: surahId,
                  fontSize: 120,
                  color: accent,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
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
