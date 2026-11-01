import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/mushaf/surah_name_glyph_metrics.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/mushaf_surah_header_cartouche.dart';

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
    // Same ink colour as the Mushaf ayah text (option-I blends with the page).
    final accent = colorScheme.onSurface;

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
/// [maxInkWidth]. One visual height for every surah; no clipping. The option-I
/// cartouche is stroked around the ink in the same colour.
class SurahNameMushafInkGlyph extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final label = surahHeaderSemanticsLabel(ref, surahId);
    return Semantics(
      image: true,
      label: label,
      child: CustomPaint(
        painter: _SurahNameInkPainter(
          surahId: surahId,
          color: color,
          targetInkHeight: targetInkHeight,
          maxInkWidth: maxInkWidth,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Localized semantics label, e.g. "Surah Al-Fil".
String surahHeaderSemanticsLabel(WidgetRef ref, int surahId) {
  final language = ref.watch(settingsProvider).appLanguage;
  final names = ref.watch(surahNamesProvider).valueOrNull;
  var name = 'Surah $surahId';
  if (names != null) {
    for (final surah in names) {
      if (surah.id == surahId) {
        name = surah.englishName;
        break;
      }
    }
  }
  final prefix = AppLocalizations.getMenuText('surah', language);
  return '$prefix $name';
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

    // Option-I cartouche around the ink: stroke only, same colour source.
    final inkRect = Rect.fromLTRB(
      (size.width - layout.inkWidth) / 2,
      layout.baselineForSlot(size.height) - layout.inkTopAboveBaseline,
      (size.width + layout.inkWidth) / 2,
      layout.baselineForSlot(size.height) - layout.inkBottomAboveBaseline,
    );
    MushafSurahEndCapsPainter(
      geometry: layoutMushafEndCaps(box: size, inkRect: inkRect),
      color: color,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_SurahNameInkPainter oldDelegate) {
    return oldDelegate.surahId != surahId ||
        oldDelegate.color != color ||
        oldDelegate.targetInkHeight != targetInkHeight ||
        oldDelegate.maxInkWidth != maxInkWidth;
  }
}

/// < 600dp Mushaf header: the 1.0.21+69 glyph size and position are untouched;
/// only the option-I cartouche and its hairlines are stroked around the ink.
class SurahNameMushafFlowHeader extends ConsumerWidget {
  const SurahNameMushafFlowHeader({
    super.key,
    required this.surahId,
    required this.mushafFontSize,
  });

  final int surahId;
  final double mushafFontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inkColor = Theme.of(context).colorScheme.onSurface;
    final label = surahHeaderSemanticsLabel(ref, surahId);
    return Semantics(
      image: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageWidth = constraints.maxWidth;
          final slotHeight =
              (mushafFontSize * 1.55).clamp(44.0, 54.0);
          final rowHeight = 28 + slotHeight;
          final ink = _flowInkRect(
            surahId: surahId,
            pageWidth: pageWidth,
            slotHeight: slotHeight,
          );
          return SizedBox(
            height: rowHeight,
            child: Stack(
              children: [
                SurahNameMushafGlyph(
                  surahId: surahId,
                  mushafFontSize: mushafFontSize,
                ),
                Positioned.fill(
                  child: MushafSurahEndCapsOverlay(
                    box: Size(pageWidth, rowHeight),
                    inkRect: ink,
                    color: inkColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Ink rect of the +69 glyph inside the header row (page coordinates).
Rect _flowInkRect({
  required int surahId,
  required double pageWidth,
  required double slotHeight,
}) {
  final ink = surahNameGlyphInkFor(surahId);
  final slotWidth = pageWidth * 0.5;
  if (ink == null || slotWidth <= 0) {
    return Rect.fromCenter(
      center: Offset(pageWidth / 2, 14 + slotHeight / 2),
      width: slotWidth,
      height: slotHeight,
    );
  }

  final natural = TextPainter(
    text: TextSpan(
      text: surahNameGlyphText(surahId),
      style: const TextStyle(
        fontFamily: 'SurahNameV2',
        fontSize: 120,
        height: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final naturalWidth = natural.width;
  natural.dispose();
  if (naturalWidth <= 0) {
    return Rect.fromCenter(
      center: Offset(pageWidth / 2, 14 + slotHeight / 2),
      width: slotWidth,
      height: slotHeight,
    );
  }

  // Matches FittedBox(fitWidth) of the +69 header.
  final fontSize = 120 * slotWidth / naturalWidth;
  final painter = TextPainter(
    text: TextSpan(
      text: surahNameGlyphText(surahId),
      style: TextStyle(
        fontFamily: 'SurahNameV2',
        fontSize: fontSize,
        height: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final metrics = painter.computeLineMetrics();
  if (metrics.isEmpty) {
    painter.dispose();
    return Rect.fromCenter(
      center: Offset(pageWidth / 2, 14 + slotHeight / 2),
      width: slotWidth,
      height: slotHeight,
    );
  }
  final baseline = metrics.first.baseline;
  painter.dispose();

  final lineHeight = fontSize * 1.1;
  final slotTop = 14.0;
  final slotLeft = (pageWidth - slotWidth) / 2;
  final scaledChildTop = slotTop + (slotHeight - lineHeight) / 2;
  final unit = fontSize / kSurahNameGlyphUnitsPerEm;
  final inkTop = scaledChildTop + baseline - ink.yMax * unit;
  final inkLeft = slotLeft + ink.xMin * unit;
  final inkWidth = ink.inkWidthUnits * unit;
  final inkHeight = ink.inkHeightUnits * unit;
  return Rect.fromLTWH(inkLeft, inkTop, inkWidth, inkHeight);
}

