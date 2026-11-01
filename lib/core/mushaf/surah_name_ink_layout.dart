import 'package:quran_offline/core/mushaf/surah_name_glyph_metrics.dart';

/// Mushaf surah header sizing.
///
/// The header occupies one row of the 15-row QPC page. It is sized by the
/// glyph's INK height (see [kSurahNameGlyphInk]), not by the font line box:
/// SurahNameV2 has large empty ascent/descent, so fitting the line box makes the
/// visible ornament much smaller than its slot.
const double kSurahNameInkHeightFactor = 0.95;

/// A surah name may use at most this share of the page text width.
const double kSurahNameMaxInkWidthFactor = 0.65;

/// Resolved ink geometry for one surah name.
class SurahNameInkLayout {
  const SurahNameInkLayout({
    required this.surahId,
    required this.fontSize,
    required this.inkWidth,
    required this.inkHeight,
    required this.inkLeft,
    required this.inkTopAboveBaseline,
    required this.inkBottomAboveBaseline,
  });

  const SurahNameInkLayout.empty(this.surahId)
    : fontSize = 0,
      inkWidth = 0,
      inkHeight = 0,
      inkLeft = 0,
      inkTopAboveBaseline = 0,
      inkBottomAboveBaseline = 0;

  final int surahId;

  /// Font size that produces [inkHeight] (ink units scaled by this size).
  final double fontSize;

  final double inkWidth;
  final double inkHeight;

  /// Ink left edge relative to the text origin.
  final double inkLeft;

  /// Ink top, in pixels above the baseline.
  final double inkTopAboveBaseline;

  /// Ink bottom, in pixels above the baseline (this font keeps ink above it).
  final double inkBottomAboveBaseline;

  bool get isEmpty => fontSize <= 0 || inkHeight <= 0;

  /// Baseline that vertically centres the ink inside a [slotHeight] slot.
  double baselineForSlot(double slotHeight) =>
      (slotHeight - inkHeight) / 2 + inkTopAboveBaseline;

  @override
  String toString() =>
      'SurahNameInkLayout(surah: $surahId, fontSize: $fontSize, '
      'ink: ${inkWidth}x$inkHeight, left: $inkLeft)';
}

/// Computes the font size and ink box for [surahId].
///
/// Every surah is normalised to the same [targetInkHeight]; only the width
/// varies. A name wider than [maxInkWidth] is scaled down as a whole.
SurahNameInkLayout layoutSurahNameInk({
  required int surahId,
  required double targetInkHeight,
  required double maxInkWidth,
  double unitsPerEm = kSurahNameGlyphUnitsPerEm,
}) {
  final ink = surahNameGlyphInkFor(surahId);
  if (ink == null ||
      targetInkHeight <= 0 ||
      ink.inkHeightUnits <= 0 ||
      unitsPerEm <= 0) {
    return SurahNameInkLayout.empty(surahId);
  }

  var fontSize = targetInkHeight * unitsPerEm / ink.inkHeightUnits;
  var inkWidth = ink.inkWidthUnits * fontSize / unitsPerEm;
  if (maxInkWidth > 0 && inkWidth > maxInkWidth) {
    fontSize *= maxInkWidth / inkWidth;
    inkWidth = maxInkWidth;
  }

  return SurahNameInkLayout(
    surahId: surahId,
    fontSize: fontSize,
    inkWidth: inkWidth,
    inkHeight: ink.inkHeightUnits * fontSize / unitsPerEm,
    inkLeft: ink.xMin * fontSize / unitsPerEm,
    inkTopAboveBaseline: ink.yMax * fontSize / unitsPerEm,
    inkBottomAboveBaseline: ink.yMin * fontSize / unitsPerEm,
  );
}
