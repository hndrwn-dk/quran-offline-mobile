import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/utils/bismillah.dart';

/// User [mushafFontSize] at this value = "fill page width" for glyph Mushaf lines.
const kMushafGlyphReferenceFontSize = 38.0;

/// Mirrors spacing in [QpcV2MushafText] — keep in sync when layout changes.
const _glyphLineHeightFactor = 1.55;
const _glyphLineVerticalPad = 4.0;
const _surahNameOuterGap = 16.0;
const _surahNameAfterAyahTop = 28.0;
const _surahNameBottomGap = 24.0;
const _gapBeforeAyahAfterSurahName = 18.0;
const _gapBeforeAyahAfterBasmallah = 12.0;
const _basmallahVerticalPad = 14.0;
const _surahNameGlyphVerticalPad = 14.0;

/// Smallest slider value for glyph Mushaf (avoids large empty margins).
const kMushafGlyphMinFontSize = 28.0;

const _fitCacheLimit = 64;
final _fitCache = <String, double>{};

/// Cached variant of [computeQpcV2PageFontSize] for scroll performance.
double computeQpcV2PageFontSizeCached({
  required String cacheKey,
  required Iterable<({String glyphText, String fontFamily, bool justify})> lines,
  required double maxFontSize,
  required double maxWidth,
}) {
  final cached = _fitCache[cacheKey];
  if (cached != null) return cached;

  final result = computeQpcV2PageFontSize(
    lines: lines,
    maxFontSize: maxFontSize,
    maxWidth: maxWidth,
  );
  _fitCache[cacheKey] = result;
  if (_fitCache.length > _fitCacheLimit) {
    _fitCache.remove(_fitCache.keys.first);
  }
  return result;
}

void clearQpcV2GlyphFitCache() => _fitCache.clear();

double _ayahLineHeight(double fontSize) =>
    fontSize * _glyphLineHeightFactor + _glyphLineVerticalPad * 2;

double _surahNameBlockHeight(double fontSize) {
  final headerHeight = (fontSize * _glyphLineHeightFactor).clamp(44.0, 54.0);
  return _surahNameGlyphVerticalPad * 2 + headerHeight;
}

/// Estimated rendered height for a Mushaf page at [fontSize].
double estimateQpcV2MushafPageHeight(
  QpcV2PageContent content,
  double fontSize,
) {
  var height = 0.0;
  var previousKind = 'none';

  for (final line in content.lines) {
    if (line.isSurahName && line.surahId != null) {
      height += previousKind == 'ayah'
          ? _surahNameAfterAyahTop
          : _surahNameOuterGap;
      height += _surahNameBlockHeight(fontSize);
      height += _surahNameBottomGap;
      previousKind = 'surah_name';
      continue;
    }

    if (line.isBasmallah) {
      final surahId = line.surahId;
      if (surahId == null || !Bismillah.shouldShowBismillah(surahId)) {
        previousKind = 'none';
        continue;
      }
      height += _basmallahVerticalPad * 2 + _ayahLineHeight(fontSize);
      previousKind = 'basmallah';
      continue;
    }

    if (!line.isAyah || line.words.isEmpty) continue;

    if (previousKind == 'surah_name') {
      height += _gapBeforeAyahAfterSurahName;
    } else if (previousKind == 'basmallah') {
      height += _gapBeforeAyahAfterBasmallah;
    }

    height += _ayahLineHeight(fontSize);
    previousKind = 'ayah';
  }

  return height;
}

/// Shrinks [widthFittedSize] until the page fits [maxHeight] and [maxWidth].
double fitQpcV2PageFontSizeToViewport({
  required QpcV2PageContent content,
  required Iterable<({String glyphText, String fontFamily, bool justify})>
      glyphLines,
  required double widthFittedSize,
  required double maxWidth,
  required double maxHeight,
}) {
  if (maxHeight <= 0 || !maxHeight.isFinite) return widthFittedSize;

  const minSize = 14.0;
  const step = 0.25;
  var size = widthFittedSize;

  while (size >= minSize) {
    final widthFit = computeQpcV2PageFontSize(
      lines: glyphLines,
      maxFontSize: size,
      maxWidth: maxWidth,
    );
    final estimated = estimateQpcV2MushafPageHeight(content, widthFit);
    if (estimated <= maxHeight) {
      return widthFit;
    }
    size -= step;
  }
  return minSize;
}

/// Smallest font size that fits every line on a page (uniform scaling).
double computeQpcV2PageFontSize({
  required Iterable<({String glyphText, String fontFamily, bool justify})> lines,
  required double maxFontSize,
  required double maxWidth,
}) {
  var effective = maxFontSize;
  for (final line in lines) {
    if (line.glyphText.isEmpty) continue;
    final fitted = fitQpcV2GlyphFontSize(
      glyphText: line.glyphText,
      fontFamily: line.fontFamily,
      maxFontSize: maxFontSize,
      maxWidth: maxWidth,
      justify: line.justify,
    );
    if (fitted < effective) effective = fitted;
  }
  return effective;
}

/// Largest uniform size where every ayah line fills the page width.
double computeQpcV2PageFillFontSize({
  required Iterable<({String glyphText, String fontFamily, bool justify})> lines,
  required double maxFontSize,
  required double maxWidth,
}) {
  var effective = maxFontSize;
  for (final line in lines) {
    if (line.glyphText.isEmpty) continue;
    final filled = _largestGlyphSizeFillingWidth(
      glyphText: line.glyphText,
      fontFamily: line.fontFamily,
      maxWidth: maxWidth,
      maxFontSize: effective,
    );
    if (filled < effective) effective = filled;
  }
  return effective;
}

double measureQpcV2GlyphLineWidth({
  required String glyphText,
  required String fontFamily,
  required double fontSize,
  required double maxWidth,
}) {
  if (glyphText.isEmpty) return 0;
  const edgeSafety = 6.0;
  final fitWidth = maxWidth - edgeSafety;
  if (fitWidth <= 0) return 0;

  final painter = TextPainter(
    text: TextSpan(
      text: glyphText,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.55,
        letterSpacing: 0,
        wordSpacing: 0,
      ),
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    textWidthBasis: TextWidthBasis.parent,
    maxLines: 1,
  )..layout(maxWidth: fitWidth);
  return painter.width;
}

double _largestGlyphSizeFillingWidth({
  required String glyphText,
  required String fontFamily,
  required double maxWidth,
  required double maxFontSize,
}) {
  const minSize = 14.0;
  const step = 0.25;
  const edgeSafety = 6.0;
  final fitWidth = maxWidth - edgeSafety;
  if (fitWidth <= 0) return minSize;

  var best = minSize;
  var size = minSize;
  while (size <= maxFontSize) {
    if (!_glyphLineFitsAtSize(glyphText, fontFamily, size, fitWidth)) break;
    best = size;
    size += step;
  }
  return best;
}

bool _glyphLineFitsAtSize(
  String glyphText,
  String fontFamily,
  double size,
  double fitWidth,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: glyphText,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: 1.55,
        letterSpacing: 0,
        wordSpacing: 0,
      ),
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    textWidthBasis: TextWidthBasis.parent,
    maxLines: 1,
  )..layout(maxWidth: fitWidth);
  return _glyphLineFits(painter, glyphText, fitWidth);
}

/// Fits a single Mushaf glyph line to [maxWidth] without clipping RTL edges.
double fitQpcV2GlyphFontSize({
  required String glyphText,
  required String fontFamily,
  required double maxFontSize,
  required double maxWidth,
  required bool justify,
}) {
  if (glyphText.isEmpty || maxWidth <= 0) return maxFontSize;

  const minSize = 14.0;
  const edgeSafety = 6.0;
  final fitWidth = maxWidth - edgeSafety;
  if (fitWidth <= 0) return minSize;

  if (_glyphLineFitsAtSize(glyphText, fontFamily, maxFontSize, fitWidth)) {
    return maxFontSize;
  }

  var lo = minSize;
  var hi = maxFontSize;
  var best = minSize;

  while (hi - lo > 0.5) {
    final mid = (lo + hi) / 2;
    if (_glyphLineFitsAtSize(glyphText, fontFamily, mid, fitWidth)) {
      best = mid;
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return best;
}

bool _glyphLineFits(TextPainter painter, String glyphText, double maxWidth) {
  if (painter.didExceedMaxLines) return false;
  if (painter.width > maxWidth) return false;

  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: glyphText.length),
  );
  if (boxes.isEmpty) {
    return painter.width <= maxWidth;
  }

  var minLeft = double.infinity;
  var maxRight = 0.0;
  for (final box in boxes) {
    if (box.left < minLeft) minLeft = box.left;
    if (box.right > maxRight) maxRight = box.right;
  }

  const margin = 1.0;
  return minLeft >= -margin && maxRight <= maxWidth + margin;
}
