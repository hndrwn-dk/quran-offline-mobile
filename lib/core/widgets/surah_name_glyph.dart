import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/surah_name_glyph_metrics.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';

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

  /// Ligature sequence for [surahId] (surah 33 uses the font's short form).
  static String ligatureFor(int surahId) => surahNameGlyphText(surahId);

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
/// This is the 1.0.21+69 single-page sizing (slot 50% x 44-54dp, fit width).
/// The two-page spread uses [SurahNameMushafInkGlyph] instead.
class SurahNameMushafGlyph extends StatelessWidget {
  const SurahNameMushafGlyph({
    super.key,
    required this.surahId,
    required this.mushafFontSize,
  });

  final int surahId;
  final double mushafFontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth.isFinite &&
                  constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width - 32;
          final headerWidth = contentWidth * 0.50;
          final headerHeight = (mushafFontSize * 1.55).clamp(44.0, 54.0);

          return Center(
            child: SizedBox(
              width: headerWidth,
              height: headerHeight,
              child: FittedBox(
                fit: BoxFit.fitWidth,
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

/// Mushaf surah header sized by its INK bounds.
///
/// The font's line box is much taller than the ornament, so fitting the box
/// (or a fixed font size) makes the header look tiny. This paints the ligature
/// at the size that gives [targetInkHeight] of visible ink, centred vertically
/// in the current slot, and scales a name down only if its ink would exceed
/// [maxInkWidth]. One visual height for every surah; no clipping.
class SurahNameMushafInkGlyph extends StatelessWidget {
  const SurahNameMushafInkGlyph({
    super.key,
    required this.surahId,
    required this.color,
    required this.targetInkHeight,
    required this.maxInkWidth,
  });

  final int surahId;
  final Color color;
  final double targetInkHeight;
  final double maxInkWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SurahNameInkPainter(
        surahId: surahId,
        color: color,
        targetInkHeight: targetInkHeight,
        maxInkWidth: maxInkWidth,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SurahNameInkPainter extends CustomPainter {
  const _SurahNameInkPainter({
    required this.surahId,
    required this.color,
    required this.targetInkHeight,
    required this.maxInkWidth,
  });

  final int surahId;
  final Color color;
  final double targetInkHeight;
  final double maxInkWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final layout = layoutSurahNameInk(
      surahId: surahId,
      targetInkHeight: targetInkHeight,
      maxInkWidth: math.min(maxInkWidth, size.width),
    );
    if (layout.isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(
        text: surahNameGlyphText(surahId),
        style: TextStyle(
          fontFamily: 'SurahNameV2',
          fontSize: layout.fontSize,
          height: 1,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final metrics = painter.computeLineMetrics();
    if (metrics.isEmpty) {
      painter.dispose();
      return;
    }

    final dx = (size.width - layout.inkWidth) / 2 - layout.inkLeft;
    final dy = layout.baselineForSlot(size.height) - metrics.first.baseline;
    painter.paint(canvas, Offset(dx, dy));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_SurahNameInkPainter oldDelegate) {
    return oldDelegate.surahId != surahId ||
        oldDelegate.color != color ||
        oldDelegate.targetInkHeight != targetInkHeight ||
        oldDelegate.maxInkWidth != maxInkWidth;
  }
}
