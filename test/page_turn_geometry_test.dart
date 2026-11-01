import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';

const _leftRect = Rect.fromLTWH(0, 0, 400, 600);
const _rightRect = Rect.fromLTWH(424, 0, 400, 600);
const _gap = 24.0;

PageTurnGeometry _spread(
  PageTurnDirection direction,
  double progress,
) {
  return PageTurnGeometry.spread(
    leftRect: _leftRect,
    rightRect: _rightRect,
    hingeGap: _gap,
    direction: direction,
    progress: progress,
  );
}

void main() {
  group('page turn plan', () {
    test('spread forward lifts the even page over the spine', () {
      final plan = pageTurnPlan(
        visiblePage: 1,
        spread: true,
        direction: PageTurnDirection.forward,
      )!;
      expect(plan.leafPage, 2); // current left page
      expect(plan.backPage, 3); // next right page
      expect(plan.revealedPage, 4); // next left page underneath
      expect(plan.stationaryPage, 1);
      expect(plan.targetIndex, 1);
      expect(plan.requiredPages, {2, 3, 4, 1});
    });

    test('spread backward mirrors it', () {
      final plan = pageTurnPlan(
        visiblePage: 4,
        spread: true,
        direction: PageTurnDirection.backward,
      )!;
      expect(plan.leafPage, 3); // current right page
      expect(plan.backPage, 2); // previous left page
      expect(plan.revealedPage, 1); // previous right page underneath
      expect(plan.stationaryPage, 4);
      expect(plan.targetIndex, 0);
    });

    test('no spread turn before page 1 or after page 604', () {
      expect(
        pageTurnPlan(
          visiblePage: 1,
          spread: true,
          direction: PageTurnDirection.backward,
        ),
        isNull,
      );
      expect(
        pageTurnPlan(
          visiblePage: 603,
          spread: true,
          direction: PageTurnDirection.forward,
        ),
        isNull,
      );
      // Both ends are still fine in the other direction.
      expect(
        pageTurnPlan(
          visiblePage: 1,
          spread: true,
          direction: PageTurnDirection.forward,
        ),
        isNotNull,
      );
      expect(
        pageTurnPlan(
          visiblePage: 604,
          spread: true,
          direction: PageTurnDirection.backward,
        ),
        isNotNull,
      );
    });

    test('single page turns one page at a time', () {
      final forward = pageTurnPlan(
        visiblePage: 7,
        spread: false,
        direction: PageTurnDirection.forward,
      )!;
      expect(forward.leafPage, 7);
      expect(forward.backPage, 8);
      expect(forward.revealedPage, 8);
      expect(forward.stationaryPage, isNull);
      expect(forward.targetIndex, 7); // page 8 -> index 7

      final backward = pageTurnPlan(
        visiblePage: 7,
        spread: false,
        direction: PageTurnDirection.backward,
      )!;
      expect(backward.backPage, 6);
      expect(backward.targetIndex, 5); // page 6 -> index 5
    });

    test('single page honours the book bounds', () {
      expect(
        pageTurnPlan(
          visiblePage: 1,
          spread: false,
          direction: PageTurnDirection.backward,
        ),
        isNull,
      );
      expect(
        pageTurnPlan(
          visiblePage: kMushafTotalPages,
          spread: false,
          direction: PageTurnDirection.forward,
        ),
        isNull,
      );
    });

    test('bounds never produce a synthetic turn', () {
      for (final spread in [true, false]) {
        expect(
          pageTurnPlan(
            visiblePage: 1,
            spread: spread,
            direction: PageTurnDirection.backward,
          ),
          isNull,
        );
        expect(
          pageTurnPlan(
            visiblePage: kMushafTotalPages,
            spread: spread,
            direction: PageTurnDirection.forward,
          ),
          isNull,
        );
      }
    });
  });

  group('drag thresholds', () {
    test('direction follows the pager: right drag advances', () {
      expect(pageTurnDirectionForDrag(12), PageTurnDirection.forward);
      expect(pageTurnDirectionForDrag(-12), PageTurnDirection.backward);
      expect(pageTurnDirectionForDrag(0), isNull);
    });

    test('progress tracks the finger and never leaves 0..1', () {
      expect(
        pageTurnDragProgress(
          deltaX: 200,
          pageWidth: 400,
          direction: PageTurnDirection.forward,
        ),
        0.5,
      );
      expect(
        pageTurnDragProgress(
          deltaX: -100,
          pageWidth: 400,
          direction: PageTurnDirection.forward,
        ),
        0,
      );
      expect(
        pageTurnDragProgress(
          deltaX: -200,
          pageWidth: 400,
          direction: PageTurnDirection.backward,
        ),
        0.5,
      );
      expect(
        pageTurnDragProgress(
          deltaX: 900,
          pageWidth: 400,
          direction: PageTurnDirection.forward,
        ),
        1,
      );
      expect(
        pageTurnDragProgress(
          deltaX: 0,
          pageWidth: 0,
          direction: PageTurnDirection.forward,
        ),
        0,
      );
    });

    test('progress is clamped with no rubber band at any bound', () {
      expect(
        pageTurnDragProgress(
          deltaX: -400,
          pageWidth: 400,
          direction: PageTurnDirection.forward,
        ),
        0,
      );
      expect(
        pageTurnDragProgress(
          deltaX: 400,
          pageWidth: 400,
          direction: PageTurnDirection.backward,
        ),
        0,
      );
      expect(
        pageTurnDragProgress(
          deltaX: -900,
          pageWidth: 400,
          direction: PageTurnDirection.backward,
        ),
        1,
      );
    });

    test('curl radius is 8–12% of the page and shrinks as it lands', () {
      final start = pageCurlRadius(400, 0);
      final end = pageCurlRadius(400, 1);
      expect(start, closeTo(40, 1e-9)); // 10%
      expect(end, closeTo(32, 1e-9)); // 8%
      expect(end, lessThan(start));
      expect(pageCurlRadius(0, 0.5), 0);
    });

    test('the curled strip is closed at both ends of the turn', () {
      expect(pageCurlBandWidth(40, 0), 0);
      expect(pageCurlBandWidth(40, 1), closeTo(0, 1e-9));
      expect(pageCurlBandWidth(40, 0.5), closeTo(40, 1e-9));
      expect(pageCurlBandWidth(40, 0.25), greaterThan(0));
    });

    test('diagonal fold offset follows the finger and vanishes at the ends',
        () {
      final top = pageCurlDiagonalOffset(
        tilt: -1,
        pageWidth: 400,
        progress: 0.25,
      );
      final bottom = pageCurlDiagonalOffset(
        tilt: 1,
        pageWidth: 400,
        progress: 0.25,
      );
      expect(top, lessThan(0));
      expect(bottom, greaterThan(0));
      expect(bottom, closeTo(-top, 1e-9));
      expect(
        pageCurlDiagonalOffset(tilt: 1, pageWidth: 400, progress: 0),
        0,
      );
      expect(
        pageCurlDiagonalOffset(tilt: 1, pageWidth: 400, progress: 1),
        closeTo(0, 1e-9),
      );
    });

    test('commit needs 35% or 700 px/s', () {
      expect(
        pageTurnShouldCommit(
          progress: kPageTurnCommitProgress,
          velocityX: 0,
          direction: PageTurnDirection.forward,
        ),
        isTrue,
      );
      expect(
        pageTurnShouldCommit(
          progress: 0.34,
          velocityX: 0,
          direction: PageTurnDirection.forward,
        ),
        isFalse,
      );
      expect(
        pageTurnShouldCommit(
          progress: 0.1,
          velocityX: kPageTurnCommitVelocity,
          direction: PageTurnDirection.forward,
        ),
        isTrue,
      );
      // A fling in the opposite direction never commits.
      expect(
        pageTurnShouldCommit(
          progress: 0.1,
          velocityX: -1200,
          direction: PageTurnDirection.forward,
        ),
        isFalse,
      );
      expect(
        pageTurnShouldCommit(
          progress: 0.1,
          velocityX: -800,
          direction: PageTurnDirection.backward,
        ),
        isTrue,
      );
    });
  });

  group('edge taps', () {
    const pages = [
      PageTurnPageRect(pageNo: 2, rect: _leftRect, isLeft: true),
      PageTurnPageRect(pageNo: 1, rect: _rightRect, isLeft: false),
    ];

    test('outer 12% of each page turns, gutter does not', () {
      // 12% of 400 = 48.
      expect(
        resolvePageTurnTap(position: const Offset(20, 300), pages: pages),
        PageTurnTapEdge.previous,
      );
      expect(
        resolvePageTurnTap(position: const Offset(810, 300), pages: pages),
        PageTurnTapEdge.next,
      );
      expect(
        resolvePageTurnTap(position: const Offset(200, 300), pages: pages),
        isNull,
      );
      expect(
        resolvePageTurnTap(position: const Offset(412, 300), pages: pages),
        isNull,
      );
      // Just inside / outside the left page's zone.
      expect(
        resolvePageTurnTap(position: const Offset(47, 300), pages: pages),
        PageTurnTapEdge.previous,
      );
      expect(
        resolvePageTurnTap(position: const Offset(49, 300), pages: pages),
        isNull,
      );
      // Inside the gutter/right page's inner (hinge) side never turns.
      expect(
        resolvePageTurnTap(position: const Offset(430, 300), pages: pages),
        isNull,
      );
    });

    test('taps outside the page area are background', () {
      expect(
        resolvePageTurnTap(position: const Offset(20, 700), pages: pages),
        isNull,
      );
    });

    test('a single page turns on both outer edges', () {
      const single = [
        PageTurnPageRect(
            pageNo: 7, rect: Rect.fromLTWH(0, 0, 390, 600), isLeft: true),
      ];
      expect(
        resolvePageTurnTap(position: const Offset(10, 300), pages: single),
        PageTurnTapEdge.previous,
      );
      expect(
        resolvePageTurnTap(position: const Offset(380, 300), pages: single),
        PageTurnTapEdge.next,
      );
      expect(
        resolvePageTurnTap(position: const Offset(195, 300), pages: single),
        isNull,
      );
    });
  });

  group('leaf geometry', () {
    test('front covers the page at 0, vanishes edge-on at 0.5', () {
      final start = _spread(PageTurnDirection.forward, 0);
      expect(start.frontRect, _leftRect);
      expect(start.frontFraction, closeTo(1, 1e-9));
      expect(start.backFraction, 0);
      expect(start.curlDepth, 0);

      final edgeOn = _spread(PageTurnDirection.forward, 0.5);
      expect(edgeOn.frontRect.isEmpty, isTrue);
      expect(edgeOn.backRect.isEmpty, isTrue);
      expect(edgeOn.curlDepth, greaterThan(0));

      final end = _spread(PageTurnDirection.forward, 1);
      expect(end.frontRect.isEmpty, isTrue);
      // The back lands exactly on the right page.
      expect(end.backRect, _rightRect);
    });

    test('pivot is the gutter centre and the free edge sweeps right', () {
      expect(_spread(PageTurnDirection.forward, 0.2).pivotX, 412);
      final quarter = _spread(PageTurnDirection.forward, 0.25);
      final half = _spread(PageTurnDirection.forward, 0.5);
      expect(quarter.frontRect.left, greaterThan(_leftRect.left));
      expect(quarter.frontRect.right, _leftRect.right);
      expect(quarter.freeEdgeSign, -1);
      expect(half.freeEdgeSign, -1);
      expect(_spread(PageTurnDirection.forward, 0.75).freeEdgeSign, 1);
    });

    test('backward mirrors front and back', () {
      final start = _spread(PageTurnDirection.backward, 0);
      expect(start.frontRect, _rightRect);
      final end = _spread(PageTurnDirection.backward, 1);
      expect(end.backRect, _leftRect);
      final quarter = _spread(PageTurnDirection.backward, 0.25);
      expect(quarter.frontRect.left, _rightRect.left);
      expect(quarter.freeEdgeSign, 1);
      expect(_spread(PageTurnDirection.backward, 0.75).freeEdgeSign, -1);
    });

    test('never paints outside the two pages', () {
      for (var p = 0.0; p <= 1.0; p += 0.05) {
        final geometry = _spread(PageTurnDirection.forward, p);
        final stage = geometry.stageRect;
        expect(stage.left, lessThanOrEqualTo(_leftRect.left));
        expect(stage.right, greaterThanOrEqualTo(_rightRect.right));
        expect(stage.top, _leftRect.top);
        expect(stage.bottom, _leftRect.bottom);
        expect(stage.overlaps(geometry.frontRect) || geometry.frontRect.isEmpty,
            isTrue);
        expect(stage.overlaps(geometry.backRect) || geometry.backRect.isEmpty,
            isTrue);
      }
    });

    test('single page hinges on its own edge and lands off the book', () {
      const page = Rect.fromLTWH(0, 0, 400, 600);
      final forward = PageTurnGeometry.single(
        pageRect: page,
        direction: PageTurnDirection.forward,
        progress: 0,
      );
      expect(forward.pivotX, page.right);
      expect(forward.frontRect, page);
      expect(forward.landedRect.left, page.right);
      expect(forward.landedRect.width, page.width);

      final backward = PageTurnGeometry.single(
        pageRect: page,
        direction: PageTurnDirection.backward,
        progress: 0.75,
      );
      expect(backward.pivotX, page.left);
      expect(backward.landedRect.right, page.left);
      expect(backward.backRect.right, closeTo(page.left, 1e-9));
    });
  });
}
