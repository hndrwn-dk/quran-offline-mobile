import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/widgets.dart';

/// QPC V2 (1421H Madinah print) page geometry.
///
/// The bundled QPC V2 page fonts use a 2500 unit em with 15 layout rows of
/// `hhea` height 1.644 em and a widest ayah line of ~16 em. That makes the
/// printed page box 16 em wide x 15 x 1.644 em tall, i.e. a width/height ratio
/// of ~0.65 — the Madani mushaf proportion the layout SQLite declares
/// ("QCF V2 ( 1421H print )").
const double kMushafPageAspectRatio = 0.65;

/// Reference layout width used by every Mushaf page before it is scaled into
/// its frame. 358 = 390dp phone width minus the 16dp page gutters, so glyph
/// composition, ayah markers and justification stay identical to the phone.
const double kMushafPageLayoutWidth = 358.0;

/// Fixed reference height of a page (15 rows tall, `0.65` ratio).
const double kMushafPageLayoutHeight =
    kMushafPageLayoutWidth / kMushafPageAspectRatio;

/// Rows in a full QPC V2 page.
const int kMushafPageLineCount = 15;

/// One row slot of the reference page.
const double kMushafPageRowHeight =
    kMushafPageLayoutHeight / kMushafPageLineCount;

/// Fixed glyph size in frame mode: 16 em page width == [kMushafPageLayoutWidth].
///
/// Frame mode ignores the user font-size slider on purpose so both pages of a
/// spread always render at exactly the same text size.
const double kMushafPageFontSize = kMushafPageLayoutWidth / 16.0;

/// Physical line height of one QPC V2 row, as a multiple of the glyph size.
const double kMushafPageLineHeightFactor =
    kMushafPageRowHeight / kMushafPageFontSize;

const int kMushafTotalPages = 604;

/// `1|2, 3|4, ... 603|604`.
const int kMushafSpreadCount = kMushafTotalPages ~/ 2;

/// Gutter between the two pages of a spread when no hinge is reported.
const double kMushafSpreadGap = 24.0;

/// Samsung reports a flat/closed fold with zero-width bounds; keep a real gap.
const double kMushafMinHingeGap = 24.0;

/// Outer breathing room around the spread inside the reader body.
const double kMushafSpreadPadding = 16.0;

/// A spread needs a wide window and two readable pages.
const double kMushafMinSpreadWindowWidth = 600.0;
const double kMushafMinSpreadPageWidth = 280.0;
const double kMushafMinSpreadPageHeight = 400.0;

/// Largest page frame that fits [available], height first then width.
///
/// The frame always keeps [aspectRatio]; a page is never stretched.
Size mushafPageFrameSize(
  Size available, {
  double aspectRatio = kMushafPageAspectRatio,
}) {
  if (!available.width.isFinite || !available.height.isFinite) {
    return Size.zero;
  }
  if (available.width <= 0 || available.height <= 0 || aspectRatio <= 0) {
    return Size.zero;
  }
  final heightFromWidth = available.width / aspectRatio;
  if (heightFromWidth <= available.height) {
    return Size(available.width, heightFromWidth);
  }
  return Size(available.height * aspectRatio, available.height);
}

/// One physical spread: even page on the left, odd page on the right.
///
/// A spread is always a pair `(2k, 2k-1)` so the odd page stays on the right
/// for every spread, including `1|2` and `603|604`.
class MushafSpreadPair {
  const MushafSpreadPair({required this.leftPage, required this.rightPage});

  /// Even page (left half).
  final int leftPage;

  /// Odd page (right half).
  final int rightPage;

  /// Page carried by [kMushafSpreadIndexForPage] / last-read default.
  int get firstPage => rightPage;

  /// Highest page in the spread.
  int get lastPage => leftPage;

  List<int> get pages => [rightPage, leftPage];

  /// Inclusive localized range, ascending: `3–4`.
  (int, int) get range => (rightPage, leftPage);

  bool contains(int pageNo) => pageNo == leftPage || pageNo == rightPage;

  @override
  bool operator ==(Object other) =>
      other is MushafSpreadPair &&
      other.leftPage == leftPage &&
      other.rightPage == rightPage;

  @override
  int get hashCode => Object.hash(leftPage, rightPage);

  @override
  String toString() => 'MushafSpreadPair($rightPage|$leftPage)';
}

/// Clamps [pageNo] into a spread; `1 -> 1|2`, `4 -> 3|4`, `604 -> 603|604`.
MushafSpreadPair mushafSpreadForPage(int pageNo) {
  final clamped = pageNo.clamp(1, kMushafTotalPages);
  final odd = clamped.isOdd ? clamped : clamped - 1;
  final even = math.min(odd + 1, kMushafTotalPages);
  return MushafSpreadPair(leftPage: even, rightPage: odd);
}

/// Zero-based spread index containing [pageNo].
int mushafSpreadIndexForPage(int pageNo) {
  return (mushafSpreadForPage(pageNo).rightPage + 1) ~/ 2 - 1;
}

/// Zero-based spread index -> the odd/right page of that spread.
int mushafSpreadPageForIndex(int index) => index * 2 + 1;

/// True when a display feature lies horizontally (fold above/below the text).
///
/// A device rotated into portrait reports a horizontal hinge; a two page
/// spread would put text across the crease, so readers force a single page.
bool mushafHasHorizontalFold(Iterable<DisplayFeature> features) {
  for (final feature in features) {
    final bounds = feature.bounds;
    if (bounds.width <= 0 && bounds.height <= 0) continue;
    if (bounds.width > bounds.height) return true;
  }
  return false;
}

/// Space reserved for a vertical hinge so no text sits on the crease.
class MushafHingeLayout {
  const MushafHingeLayout({
    this.leftInset = 0,
    this.rightInset = 0,
    this.gap = kMushafSpreadGap,
  });

  /// Extra space on the left of the spread (aligns the gutter with the hinge).
  final double leftInset;

  /// Extra space on the right of the spread.
  final double rightInset;

  /// Gutter between the two page frames.
  final double gap;

  double get horizontalInsets => leftInset + rightInset;

  @override
  String toString() =>
      'MushafHingeLayout(left: $leftInset, right: $rightInset, gap: $gap)';
}

/// Places the spread gutter on a vertical hinge, if one is reported.
///
/// [size] is the window size. When the hinge is not centred the pair is shifted
/// with asymmetric insets (padding of `2 * delta` shifts the centred content
/// by `delta`).
MushafHingeLayout mushafHingeLayout({
  required Size size,
  required Iterable<DisplayFeature> displayFeatures,
  double fallbackGap = kMushafSpreadGap,
}) {
  DisplayFeature? vertical;
  for (final feature in displayFeatures) {
    final bounds = feature.bounds;
    if (bounds.width <= 0 && bounds.height <= 0) continue;
    if (bounds.width > bounds.height) continue;
    vertical = feature;
    break;
  }
  if (vertical == null) {
    return MushafHingeLayout(gap: fallbackGap);
  }

  final bounds = vertical.bounds;
  final gap = math.max(bounds.width, kMushafMinHingeGap);
  final delta = bounds.center.dx - size.width / 2;
  return MushafHingeLayout(
    leftInset: delta > 0 ? delta * 2 : 0,
    rightInset: delta < 0 ? -delta * 2 : 0,
    gap: gap,
  );
}

/// Outcome of the spread decision for one window size.
class MushafSpreadMetrics {
  const MushafSpreadMetrics({
    required this.showSpread,
    required this.pageSize,
    required this.hinge,
    this.reason = '',
  });

  /// Whether two pages should be shown side by side.
  final bool showSpread;

  /// Frame size of one page. In single mode this is the single page frame.
  final Size pageSize;

  final MushafHingeLayout hinge;

  /// Human readable gate reason (debug logging on device).
  final String reason;

  @override
  String toString() =>
      'MushafSpreadMetrics(showSpread: $showSpread, pageSize: $pageSize, '
      'hinge: $hinge, reason: $reason)';
}

/// Decides single vs spread for the reader body area.
///
/// [available] is the post-chrome body size (AppBar, status bar and system
/// insets already removed). [padding] is used for the single-page frame only.
MushafSpreadMetrics resolveMushafSpread({
  required Size available,
  required List<DisplayFeature> displayFeatures,
  required bool spreadEnabled,
  double gap = kMushafSpreadGap,
  double padding = kMushafSpreadPadding,
}) {
  final hinge = mushafHingeLayout(
    size: available,
    displayFeatures: displayFeatures,
    fallbackGap: gap,
  );
  final horizontalFold = mushafHasHorizontalFold(displayFeatures);

  final singlePage = mushafPageFrameSize(
    Size(
      math.max(0, available.width - padding * 2),
      available.height,
    ),
  );

  if (!spreadEnabled) {
    return MushafSpreadMetrics(
      showSpread: false,
      pageSize: singlePage,
      hinge: hinge,
      reason: 'setting off',
    );
  }
  if (horizontalFold) {
    return MushafSpreadMetrics(
      showSpread: false,
      pageSize: singlePage,
      hinge: hinge,
      reason: 'horizontal fold',
    );
  }
  if (available.width < kMushafMinSpreadWindowWidth) {
    return MushafSpreadMetrics(
      showSpread: false,
      pageSize: singlePage,
      hinge: hinge,
      reason: 'window width ${available.width.round()} < '
          '${kMushafMinSpreadWindowWidth.round()}',
    );
  }

  final spreadWidth = math.max(
    0.0,
    available.width - padding * 2 - hinge.gap - hinge.horizontalInsets,
  );
  final spreadPage = mushafPageFrameSize(
    Size(
      spreadWidth / 2,
      available.height,
    ),
  );

  if (spreadPage.width < kMushafMinSpreadPageWidth) {
    return MushafSpreadMetrics(
      showSpread: false,
      pageSize: singlePage,
      hinge: hinge,
      reason: 'page width ${spreadPage.width.toStringAsFixed(1)} < '
          '${kMushafMinSpreadPageWidth.round()}',
    );
  }
  if (spreadPage.height < kMushafMinSpreadPageHeight) {
    return MushafSpreadMetrics(
      showSpread: false,
      pageSize: singlePage,
      hinge: hinge,
      reason: 'page height ${spreadPage.height.toStringAsFixed(1)} < '
          '${kMushafMinSpreadPageHeight.round()}',
    );
  }

  return MushafSpreadMetrics(
    showSpread: true,
    pageSize: spreadPage,
    hinge: hinge,
    reason: 'spread',
  );
}

/// Uniform scale applied to the reference page inside its frame.
///
/// Both pages of a spread share the same frame size, therefore the same scale
/// and the same rendered text size.
double mushafPageScaleFor(Size frameSize) {
  if (frameSize.width <= 0 || kMushafPageLayoutWidth <= 0) return 1;
  return frameSize.width / kMushafPageLayoutWidth;
}
