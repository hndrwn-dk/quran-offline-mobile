import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, Rect, Size;

import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_page_ink_metrics.dart';

/// Framed Mushaf (window >= 600dp) laid out as paper sheets on a desk.
///
/// Normal mode: the ayah text box (the fixed QPC reference page, uniformly
/// scaled) never gets smaller than the 1.0.23 layout gave the same window;
/// decorations only use space the text does not need, and are dropped in a
/// fixed order when they do not fit: rosettes, inner frame line, outer line.
///
/// Focus mode (bars hidden) always shows the outer frame line and the page
/// number on every spread, and the text takes the rest ([resolveMushafFocusSheetLayout]).
/// On the Fold that is 26.67dp instead of 27.66dp: an approved trade-off.

/// Minimum distance between any frame line or rosette and the line ink.
const double kMushafInkClearance = 6.0;

/// Sheet edge to the centre of the outer frame line (outer side, top, bottom).
const double kMushafFrameEdgeInset = 3.0;

/// Same on the spine side: deeper, so the two sheets' frame lines keep a clear
/// gap at the fold instead of reading as one thick centre bar.
const double kMushafFrameSpineInset = 7.0;

/// Outer line centre to inner line centre.
const double kMushafFrameLineGap = 3.5;

const double kMushafFrameOuterStroke = 1.0;
const double kMushafFrameInnerStroke = 0.5;

/// Corner rosette (two squares at 0°/45° + a circle), full extent. Drawn on
/// the outer corners only; the spine side has none.
const double kMushafRosetteSize = 13.0;

/// Paper around the ink when no frame fits (the 1.0.23 page body padding).
const double kMushafPlainMargin = 2.0;

/// Last resort: the 1.0.23 page body padding (2dp), so text never shrinks.
const double kMushafBareMargin = 2.0;

/// Page number line box ("· ٦٠٣ ·"), its gap to the ink above and to the
/// frame line (or sheet edge) below.
const double kMushafSheetNumberFontSize = 14.0;
const double kMushafSheetNumberHeight = 14.0;
const double kMushafSheetNumberGap = 4.0;
const double kMushafSheetNumberFrameGap = 2.5;

/// One page-stack edge (offset paper edge) on a sheet's outer side.
const double kMushafStackEdgeStep = 1.0;
const int kMushafStackMaxEdges = 5;

/// Width kept free outside every sheet for its stack, so the layout does not
/// move while paging from 1|2 (thin right stack) to 603|604 (thick right).
const double kMushafStackReserve = kMushafStackEdgeStep * kMushafStackMaxEdges;

/// Decorations drawn on a sheet, richest first.
enum MushafSheetDecor {
  /// Outer + inner frame lines and corner rosettes.
  full,

  /// Outer + inner frame lines.
  doubleFrame,

  /// Outer frame line only.
  outerFrame,

  /// Paper only.
  plain;

  bool get hasOuterFrame => this != plain;
  bool get hasInnerFrame => this == full || this == doubleFrame;
  bool get hasRosettes => this == full;

  /// Sheet edge to the inner side of the innermost decoration.
  double get decorationDepth => switch (this) {
        full => kMushafRosetteSize,
        doubleFrame => kMushafFrameEdgeInset +
            kMushafFrameLineGap +
            kMushafFrameInnerStroke / 2,
        outerFrame => kMushafFrameEdgeInset + kMushafFrameOuterStroke / 2,
        plain => 0,
      };

  /// Spine side: sheet edge to the inner side of the innermost frame line.
  double get spineDepth => switch (this) {
        full || doubleFrame => kMushafFrameSpineInset +
            kMushafFrameLineGap +
            kMushafFrameInnerStroke / 2,
        outerFrame => kMushafFrameSpineInset + kMushafFrameOuterStroke / 2,
        plain => 0,
      };

  /// Top: sheet edge to the ink limit (text box + worst overhang).
  double get margin => this == plain
      ? kMushafPlainMargin
      : decorationDepth + kMushafInkClearance;

  /// Both sides (mirrored): the deeper of the outer and spine decorations.
  double get sideMargin => this == plain
      ? kMushafPlainMargin
      : math.max(decorationDepth, spineDepth) + kMushafInkClearance;

  /// Sheet bottom edge to the innermost frame line (where the number sits).
  double get bottomLineDepth => switch (this) {
        full || doubleFrame => kMushafFrameEdgeInset +
            kMushafFrameLineGap +
            kMushafFrameInnerStroke / 2,
        outerFrame => kMushafFrameEdgeInset + kMushafFrameOuterStroke / 2,
        plain => 0,
      };

  /// Bottom, sheet edge to the ink limit, with the page number in between.
  double get bottomMarginWithNumber => math.max(
        margin,
        bottomLineDepth +
            kMushafSheetNumberFrameGap +
            kMushafSheetNumberHeight +
            kMushafSheetNumberGap,
      );
}

/// Vertical crease to keep text off, without the legacy 24dp minimum: the
/// mirrored inner margins of both sheets already keep text off the fold.
MushafHingeLayout mushafSheetHinge({
  required Size size,
  required Iterable<DisplayFeature> displayFeatures,
}) {
  for (final feature in displayFeatures) {
    final bounds = feature.bounds;
    if (bounds.width <= 0 && bounds.height <= 0) continue;
    if (bounds.width > bounds.height) continue;
    final delta = bounds.center.dx - size.width / 2;
    return MushafHingeLayout(
      leftInset: delta > 0 ? delta * 2 : 0,
      rightInset: delta < 0 ? -delta * 2 : 0,
      gap: bounds.width,
    );
  }
  return const MushafHingeLayout(gap: 0);
}

/// Page frame the 1.0.23 framed layout gave [area]: the never-shrink floor.
///
/// [verticalChrome] is the height the 1.0.23 tree spent inside [area] on top
/// of the page body paddings (badge, its gaps, the taller AppBar, ...).
Size mushafLegacyTextFrame({
  required Size area,
  required int pageCount,
  required double verticalChrome,
  MushafHingeLayout hinge = const MushafHingeLayout(),
}) {
  // MushafPageBody framed padding: 2dp on every side.
  const bodyPadding = 4.0;
  final height = area.height - verticalChrome - bodyPadding;
  final double width;
  if (pageCount == 2) {
    // _MushafSpread: 8dp outer padding + gutter, two Expanded halves.
    width = (area.width - 16 - hinge.horizontalInsets - hinge.gap) / 2 -
        bodyPadding;
  } else {
    width = area.width - bodyPadding;
  }
  return mushafPageFrameSize(Size(math.max(0, width), math.max(0, height)));
}

/// Resolved placement of one or two sheets in the framed reader area.
class MushafSheetLayout {
  const MushafSheetLayout({
    required this.decor,
    required this.showNumber,
    required this.textSize,
    required this.sideMargin,
    required this.topMargin,
    required this.bottomMargin,
    required this.sheets,
    required this.texts,
    this.showStack = true,
    this.inkBelowText = 0,
  });

  final MushafSheetDecor decor;

  /// Room below the text box kept for overhanging ink (the page number sits
  /// under it).
  final double inkBelowText;

  /// False only for the last-resort bare layout (no room for the stack).
  final bool showStack;
  final bool showNumber;

  /// Scaled reference page (the 15-row text box) of every sheet.
  final Size textSize;
  final double sideMargin;
  final double topMargin;
  final double bottomMargin;

  /// Sheet rects in area coordinates, left to right.
  final List<Rect> sheets;

  /// Text box rects in area coordinates, left to right.
  final List<Rect> texts;

  double get scale => mushafPageScaleFor(textSize);
  double get fontSize => kMushafPageFontSize * scale;

  @override
  String toString() => 'MushafSheetLayout($decor, number: $showNumber, '
      'text: ${textSize.width.toStringAsFixed(1)}x'
      '${textSize.height.toStringAsFixed(1)}, '
      'font: ${fontSize.toStringAsFixed(2)}dp, sheets: $sheets)';
}

/// Focus mode: outer frame line + page number on every spread, the largest
/// text that fits around them. No inner line; the corner rosettes would hang
/// off the paper at the outer line's 3dp inset, so focus mode has none.
MushafSheetLayout resolveMushafFocusSheetLayout({
  required Size area,
  required int pageCount,
  MushafHingeLayout hinge = const MushafHingeLayout(gap: 0),
  double sideInset = 0,
}) {
  return _layoutFor(
    area: area,
    pageCount: pageCount,
    hinge: hinge,
    sideInset: sideInset,
    decor: MushafSheetDecor.outerFrame,
    showNumber: true,
  );
}

/// Lays out [pageCount] sheets in [area] with the richest decoration whose
/// text is at least as large as [floor] (the 1.0.23 frame).
///
/// [sideInset] is a cutout/hinge inset on either side; it is mirrored so both
/// outer edges keep the same clearance.
MushafSheetLayout resolveMushafSheetLayout({
  required Size area,
  required int pageCount,
  required Size floor,
  MushafHingeLayout hinge = const MushafHingeLayout(gap: 0),
  double sideInset = 0,
  bool wantNumber = true,
}) {
  final candidates = <(MushafSheetDecor, bool, double, bool)>[
    for (final decor in MushafSheetDecor.values)
      (decor, wantNumber, sideInset, false),
    // Then without the page number (focus mode hid the old badge too).
    (MushafSheetDecor.plain, false, sideInset, false),
    // Last resort: the 1.0.23 page padding, no stack, no mirrored cutout.
    (MushafSheetDecor.plain, false, 0, true),
  ];

  late MushafSheetLayout layout;
  for (final (decor, number, inset, bare) in candidates) {
    layout = _layoutFor(
      area: area,
      pageCount: pageCount,
      hinge: hinge,
      sideInset: inset,
      decor: decor,
      showNumber: number,
      bare: bare,
    );
    if (layout.textSize.width >= floor.width - 0.01) return layout;
  }
  // Nothing reaches the floor (tiny window): the largest text we can give.
  return layout;
}

MushafSheetLayout _layoutFor({
  required Size area,
  required int pageCount,
  required MushafHingeLayout hinge,
  required double sideInset,
  required MushafSheetDecor decor,
  required bool showNumber,
  bool bare = false,
}) {
  final fixedSide = bare ? kMushafBareMargin : decor.sideMargin;
  final fixedTop = bare ? kMushafBareMargin : decor.margin;
  final fixedBottom = showNumber ? decor.bottomMarginWithNumber : fixedTop;

  final usableWidth = area.width -
      hinge.horizontalInsets -
      hinge.gap -
      sideInset * 2 -
      (bare ? 0 : kMushafStackReserve * 2);
  final perPageWidth = usableWidth / pageCount - fixedSide * 2;
  final perPageHeight = area.height - fixedTop - fixedBottom;

  // Glyph ink pokes past the text box (diacritics above the first line,
  // swashes); the worst case over all 604 pages scales with the text, so the
  // margins reserve it too. The bare fallback keeps the 1.0.23 geometry.
  final overSide = bare ? 0.0 : kQpcV2InkOverhangSide;
  final overTop = bare ? 0.0 : kQpcV2InkOverhangTop;
  final overBottom = bare ? 0.0 : kQpcV2InkOverhangBottom;
  final width = math.max(
    0.0,
    math.min(
      perPageWidth / (1 + 2 * overSide / kMushafPageLayoutWidth),
      perPageHeight /
          (1 / kMushafPageAspectRatio +
              (overTop + overBottom) / kMushafPageLayoutWidth),
    ),
  );
  final textSize = Size(width, width / kMushafPageAspectRatio);
  final scale = mushafPageScaleFor(textSize);
  final side = fixedSide + overSide * scale;
  final top = fixedTop + overTop * scale;
  final bottom = fixedBottom + overBottom * scale;

  final sheetSize = Size(
    textSize.width + side * 2,
    textSize.height + top + bottom,
  );

  // Centre the spread on the gutter; leftover width goes to the outer sides.
  final gutterX = hinge.leftInset + (area.width - hinge.horizontalInsets) / 2;
  final sheetTop = (area.height - sheetSize.height) / 2;
  final sheets = <Rect>[];
  if (pageCount == 2) {
    sheets
      ..add(Rect.fromLTWH(
        gutterX - hinge.gap / 2 - sheetSize.width,
        sheetTop,
        sheetSize.width,
        sheetSize.height,
      ))
      ..add(Rect.fromLTWH(
        gutterX + hinge.gap / 2,
        sheetTop,
        sheetSize.width,
        sheetSize.height,
      ));
  } else {
    sheets.add(Rect.fromLTWH(
      gutterX - sheetSize.width / 2,
      sheetTop,
      sheetSize.width,
      sheetSize.height,
    ));
  }
  final texts = [
    for (final sheet in sheets)
      Rect.fromLTWH(
        sheet.left + side,
        sheet.top + top,
        textSize.width,
        textSize.height,
      ),
  ];

  return MushafSheetLayout(
    decor: decor,
    showNumber: showNumber,
    textSize: textSize,
    sideMargin: side,
    topMargin: top,
    bottomMargin: bottom,
    sheets: sheets,
    texts: texts,
    showStack: !bare,
    inkBelowText: overBottom * scale,
  );
}

/// Offset paper edges on a sheet's outer side, 1..[kMushafStackMaxEdges].
///
/// RTL book: the read pages pile up on the right, the remaining ones on the
/// left. [pageNo] is the page on that sheet; [onRight] is the sheet's side.
int mushafStackEdgeCount({required int pageNo, required bool onRight}) {
  final read = (pageNo - 1).clamp(0, kMushafTotalPages - 1);
  final fraction = onRight
      ? read / (kMushafTotalPages - 1)
      : 1 - read / (kMushafTotalPages - 1);
  return 1 + (fraction * (kMushafStackMaxEdges - 1)).round();
}
