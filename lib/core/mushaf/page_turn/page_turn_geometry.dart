// Pure geometry, thresholds and bounds for the Mushaf leaf (page) turn.
//
// The reader lays a spread out with the even page on the left and the odd page
// on the right (always LTR, see `MushafSpreadRow`); the leaf therefore always
// turns left to right when the reader advances, independent of the app
// language. A forward drag is a rightward drag on the pager (the reader uses
// `PageView(reverse: true)`, so a rightward drag advances an index).

import 'dart:math' as math;
import 'dart:ui' show Rect, Offset;

import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';

/// Progress at which a released drag completes instead of springing back.
const double kPageTurnCommitProgress = 0.35;

/// Release velocity (px/s) that completes a turn regardless of progress.
const double kPageTurnCommitVelocity = 700.0;

/// Animated completion / spring-back after the finger is lifted.
const Duration kPageTurnDuration = Duration(milliseconds: 400);

/// Audio-driven (non interactive) turn duration.
const Duration kPageTurnPlayDuration = Duration(milliseconds: 420);

/// Fraction of a page width at the outer edges that turns on tap.
const double kPageTurnEdgeTapFraction = 0.12;

/// Largest progress a drag at page 1 / page 604 may show (rubber band).
const double kPageTurnMaxOverscroll = 0.06;

/// Free-edge bow as a fraction of the page width (0 = flat paper).
const double kPageTurnCurlDepthFactor = 0.06;

/// Mesh resolution of the curled leaf (columns x rows of quads).
const int kPageTurnMeshColumns = 12;
const int kPageTurnMeshRows = 4;

/// Neighbour page snapshots kept rasterized while idle.
const int kPageTurnMaxCachedSnapshots = 4;

/// Which way the leaf turns.
enum PageTurnDirection {
  /// Advance: the left page lifts and lands on the right page.
  forward,

  /// Go back: the right page lifts and lands on the left page.
  backward,
}

/// Which side of a single page a tap hit.
enum PageTurnTapEdge { previous, next }

/// One page area on screen, in the coordinate space of the reader body.
class PageTurnPageRect {
  const PageTurnPageRect({
    required this.pageNo,
    required this.rect,
    required this.isLeft,
  });

  final int pageNo;
  final Rect rect;

  /// Left half of a spread (even page), or the only page in single mode.
  final bool isLeft;

  @override
  String toString() => 'PageTurnPageRect($pageNo, $rect, left: $isLeft)';
}

/// Everything the reader needs to animate one turn.
///
/// All page numbers are resolved here so the widget layer never has to know the
/// spread arithmetic: `forward` shows [backPage] on the leaf's back while
/// [revealedPage] waits underneath; [stationaryPage] stays put (spread only).
class PageTurnPlan {
  const PageTurnPlan({
    required this.direction,
    required this.spread,
    required this.leafPage,
    required this.backPage,
    required this.revealedPage,
    required this.targetIndex,
    this.stationaryPage,
  });

  final PageTurnDirection direction;
  final bool spread;

  /// Page printed on the front of the lifted leaf.
  final int leafPage;

  /// Page printed on the back of the lifted leaf (lands on the revealed page).
  final int backPage;

  /// Neighbour page revealed under the lifted leaf.
  final int revealedPage;

  /// The other page of the current spread (never lifted).
  final int? stationaryPage;

  /// Pager index shown once the turn completes.
  final int targetIndex;

  bool get isForward => direction == PageTurnDirection.forward;

  /// Page numbers whose snapshots the turn needs.
  Set<int> get requiredPages => {
        leafPage,
        backPage,
        revealedPage,
        if (stationaryPage != null) stationaryPage!,
      };

  @override
  String toString() => 'PageTurnPlan(${direction.name}, spread: $spread, '
      'leaf: $leafPage, back: $backPage, revealed: $revealedPage, '
      'stationary: $stationaryPage, index: $targetIndex)';
}

/// Resolves one turn from the page/spread currently in view.
///
/// Returns `null` at the book bounds (before page 1, after page 604), which the
/// reader turns into a small rubber-band overscroll while dragging.
PageTurnPlan? pageTurnPlan({
  required int visiblePage,
  required bool spread,
  required PageTurnDirection direction,
  int totalPages = kMushafTotalPages,
}) {
  if (totalPages <= 0) return null;
  final page = visiblePage.clamp(1, totalPages);
  if (spread) {
    final pair = mushafSpreadForPage(page);
    if (direction == PageTurnDirection.forward) {
      // Next spread is 3|4 from 1|2: lift the even (left) page, land on the odd.
      if (pair.rightPage + 2 > totalPages) return null;
      return PageTurnPlan(
        direction: direction,
        spread: true,
        leafPage: pair.leftPage,
        backPage: pair.rightPage + 2,
        revealedPage: pair.leftPage + 2,
        stationaryPage: pair.rightPage,
        targetIndex: mushafSpreadIndexForPage(pair.rightPage + 2),
      );
    }
    // Previous spread: lift the odd (right) page, land on the even page.
    if (pair.rightPage - 2 < 1) return null;
    return PageTurnPlan(
      direction: direction,
      spread: true,
      leafPage: pair.rightPage,
      backPage: pair.leftPage - 2,
      revealedPage: pair.rightPage - 2,
      stationaryPage: pair.leftPage,
      targetIndex: mushafSpreadIndexForPage(pair.rightPage - 2),
    );
  }

  if (direction == PageTurnDirection.forward) {
    if (page >= totalPages) return null;
    return PageTurnPlan(
      direction: direction,
      spread: false,
      leafPage: page,
      backPage: page + 1,
      revealedPage: page + 1,
      targetIndex: page, // index == pageNo - 1 for page + 1
    );
  }
  if (page <= 1) return null;
  return PageTurnPlan(
    direction: direction,
    spread: false,
    leafPage: page,
    backPage: page - 1,
    revealedPage: page - 1,
    targetIndex: page - 2, // index == pageNo - 1 for page - 1
  );
}

/// Synthetic plan used at the book bounds: the leaf only rubber-bands.
///
/// There is no page to turn to, so the leaf, its back and the page underneath are
/// all the page the reader is on; the drag is capped at
/// [kPageTurnMaxOverscroll] and always springs back.
PageTurnPlan pageTurnRubberBandPlan({
  required int visiblePage,
  required bool spread,
  required PageTurnDirection direction,
  int totalPages = kMushafTotalPages,
}) {
  final page = visiblePage.clamp(1, totalPages);
  if (spread) {
    final pair = mushafSpreadForPage(page);
    final leaf =
        direction == PageTurnDirection.forward ? pair.leftPage : pair.rightPage;
    final stationary =
        direction == PageTurnDirection.forward ? pair.rightPage : pair.leftPage;
    return PageTurnPlan(
      direction: direction,
      spread: true,
      leafPage: leaf,
      backPage: leaf,
      revealedPage: leaf,
      stationaryPage: stationary,
      targetIndex: mushafSpreadIndexForPage(pair.rightPage),
    );
  }
  return PageTurnPlan(
    direction: direction,
    spread: false,
    leafPage: page,
    backPage: page,
    revealedPage: page,
    targetIndex: page - 1,
  );
}

/// Maps a horizontal drag delta to a turn direction.
///
/// The Mushaf pager is `reverse: true`, so dragging right advances. The app
/// language does not change this: the spread is always laid out LTR.
PageTurnDirection? pageTurnDirectionForDrag(double deltaX) {
  if (deltaX == 0) return null;
  return deltaX > 0 ? PageTurnDirection.forward : PageTurnDirection.backward;
}

/// Progress of an interactive drag, with a damped overscroll past the bounds.
///
/// [pageWidth] is the leaf width; [blocked] is true when there is no page to
/// turn to (page 1 / 604).
double pageTurnDragProgress({
  required double deltaX,
  required double pageWidth,
  required PageTurnDirection direction,
  bool blocked = false,
}) {
  if (pageWidth <= 0) return 0;
  final forward = direction == PageTurnDirection.forward;
  // The leaf moves in the same direction as the finger for a forward turn.
  final travel = forward ? deltaX : -deltaX;
  final raw = travel / pageWidth;
  if (blocked) {
    if (raw <= 0) return 0;
    // Rubber band: never pass the small overscroll allowance.
    return kPageTurnMaxOverscroll * (1 - math.exp(-raw * 4));
  }
  return raw.clamp(0.0, 1.0);
}

/// Whether a released drag should complete the turn.
bool pageTurnShouldCommit({
  required double progress,
  required double velocityX,
  required PageTurnDirection direction,
}) {
  if (progress >= kPageTurnCommitProgress) return true;
  final forward = direction == PageTurnDirection.forward;
  final velocity = forward ? velocityX : -velocityX;
  return velocity >= kPageTurnCommitVelocity;
}

/// Hit-tests an edge tap.
///
/// [pages] are the visible page areas. In a spread only the *outer* edge of each
/// page turns (left edge of the left page goes back, right edge of the right
/// page goes forward); the gutter never turns. In single mode both outer edges
/// of the one page turn.
PageTurnTapEdge? resolvePageTurnTap({
  required Offset position,
  required List<PageTurnPageRect> pages,
  double edgeFraction = kPageTurnEdgeTapFraction,
}) {
  if (pages.isEmpty || edgeFraction <= 0) return null;
  final fraction = edgeFraction.clamp(0.0, 0.49);
  final spread = pages.length > 1;
  for (final page in pages) {
    final rect = page.rect;
    if (position.dy < rect.top || position.dy > rect.bottom) continue;
    if (position.dx < rect.left || position.dx > rect.right) continue;
    final edge = rect.width * fraction;
    if (spread) {
      if (page.isLeft && position.dx <= rect.left + edge) {
        return PageTurnTapEdge.previous;
      }
      if (!page.isLeft && position.dx >= rect.right - edge) {
        return PageTurnTapEdge.next;
      }
      continue;
    }
    if (position.dx <= rect.left + edge) return PageTurnTapEdge.previous;
    if (position.dx >= rect.right - edge) return PageTurnTapEdge.next;
  }
  return null;
}

/// Projected leaf geometry for one progress value in `0..1`.
///
/// The leaf hinges on the gutter centre ([pivotX]). The front is visible for the
/// first half of the turn, the back for the second half; the projected width
/// follows `cos(pi * progress)` like a sheet of paper seen edge-on at 90°.
class PageTurnGeometry {
  const PageTurnGeometry._({
    required this.direction,
    required this.progress,
    required this.leafRect,
    required this.landedRect,
    required this.stationaryRect,
    required this.pivotX,
    required this.hingeGap,
    required this.spread,
  });

  /// Spread turn: [leftRect]/[rightRect] are the two page areas.
  factory PageTurnGeometry.spread({
    required Rect leftRect,
    required Rect rightRect,
    required double hingeGap,
    required PageTurnDirection direction,
    required double progress,
  }) {
    final forward = direction == PageTurnDirection.forward;
    final pivot = (leftRect.right + rightRect.left) / 2;
    return PageTurnGeometry._(
      direction: direction,
      progress: progress.clamp(0.0, 1.0),
      leafRect: forward ? leftRect : rightRect,
      landedRect: forward ? rightRect : leftRect,
      stationaryRect: forward ? rightRect : leftRect,
      pivotX: pivot,
      hingeGap: hingeGap,
      spread: true,
    );
  }

  /// Single page turn: the leaf hinges on the page edge in the turn direction.
  factory PageTurnGeometry.single({
    required Rect pageRect,
    required PageTurnDirection direction,
    required double progress,
  }) {
    final forward = direction == PageTurnDirection.forward;
    final offBook = Rect.fromLTWH(
      forward ? pageRect.right : pageRect.left - pageRect.width,
      pageRect.top,
      pageRect.width,
      pageRect.height,
    );
    return PageTurnGeometry._(
      direction: direction,
      progress: progress.clamp(0.0, 1.0),
      leafRect: pageRect,
      // The facing page of a single page is off the book: the leaf lands in the
      // margin beside it, so the turn never shows a duplicate of the new page.
      landedRect: offBook,
      stationaryRect: null,
      pivotX: forward ? pageRect.right : pageRect.left,
      hingeGap: 0,
      spread: false,
    );
  }

  final PageTurnDirection direction;
  final double progress;

  /// Page the leaf is lifting from (normal orientation at progress 0).
  final Rect leafRect;

  /// Where the back of the leaf lands at progress 1.
  final Rect landedRect;

  /// The other visible page of a spread (null for a single page).
  final Rect? stationaryRect;

  /// Hinge line: gutter centre for a spread, page edge for a single page.
  final double pivotX;

  final double hingeGap;
  final bool spread;

  bool get isForward => direction == PageTurnDirection.forward;

  /// 0 (flat page) .. 1 (edge-on at half a turn).
  double get angle => math.pi * progress;

  /// Visible width factor of the front (1 at progress 0, 0 at 0.5).
  double get frontFraction => math.max(0.0, math.cos(angle));

  /// Visible width factor of the back (0 at 0.5, 1 at progress 1).
  double get backFraction => math.max(0.0, -math.cos(angle));

  /// Widest projected front (the printed page width).
  double get frontMaxWidth => leafRect.width;

  /// Widest projected back (the target page width).
  double get backMaxWidth => landedRect.width;

  /// Projected front rect (empty once the leaf is edge-on).
  ///
  /// The hinge edge of the printed page stays where it is and the free edge
  /// sweeps across the page, so progress 0 is pixel-identical to the page.
  Rect get frontRect {
    final width = frontMaxWidth * frontFraction;
    if (width <= 0) return Rect.zero;
    return isForward
        ? Rect.fromLTWH(
            leafRect.right - width,
            leafRect.top,
            width,
            leafRect.height,
          )
        : Rect.fromLTWH(
            leafRect.left,
            leafRect.top,
            width,
            leafRect.height,
          );
  }

  /// Projected back rect (empty before half a turn).
  ///
  /// Grows out of the spine on the landing page and is flush with that page at
  /// progress 1, so landing swaps to the live page without a shift.
  Rect get backRect {
    final width = backMaxWidth * backFraction;
    if (width <= 0) return Rect.zero;
    return isForward
        ? Rect.fromLTWH(
            landedRect.left,
            landedRect.top,
            width,
            landedRect.height,
          )
        : Rect.fromLTWH(
            landedRect.right - width,
            landedRect.top,
            width,
            landedRect.height,
          );
  }

  /// Free (outer) edge of whichever side is visible.
  double get freeEdgeX {
    if (progress <= 0.5) {
      final rect = frontRect;
      if (rect.isEmpty) {
        // Edge-on: the fold sits on the printed page's spine edge.
        return isForward ? leafRect.right : leafRect.left;
      }
      return isForward ? rect.left : rect.right;
    }
    final rect = backRect;
    if (rect.isEmpty) {
      return isForward ? landedRect.left : landedRect.right;
    }
    return isForward ? rect.right : rect.left;
  }

  /// Direction of the free edge from the pivot: `-1` to the left, `+1` right.
  double get freeEdgeSign {
    if (progress <= 0.5) return isForward ? -1 : 1;
    return isForward ? 1 : -1;
  }

  /// Maximal outward bow of the free edge, in logical pixels.
  double get curlDepth {
    final width = leafRect.width;
    if (width <= 0) return 0;
    return width *
        kPageTurnCurlDepthFactor *
        math.sin(math.pi * progress).clamp(0.0, 1.0);
  }

  /// Rect covering every pixel the turn can paint (both pages of a spread).
  Rect get stageRect {
    var rect = leafRect.expandToInclude(landedRect);
    final stationary = stationaryRect;
    if (stationary != null) rect = rect.expandToInclude(stationary);
    return rect;
  }

  @override
  String toString() => 'PageTurnGeometry(${direction.name}, p: '
      '${progress.toStringAsFixed(2)}, pivot: ${pivotX.toStringAsFixed(1)}, '
      'front: $frontRect, back: $backRect)';
}
