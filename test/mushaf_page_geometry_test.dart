import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';

DisplayFeature _verticalFold(double centerX, {double width = 0}) {
  return DisplayFeature(
    bounds: Rect.fromLTWH(centerX - width / 2, 0, width, 704),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureFlat,
  );
}

DisplayFeature _horizontalFold(double centerY, {double height = 0}) {
  return DisplayFeature(
    bounds: Rect.fromLTWH(0, centerY - height / 2, 933, height),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureFlat,
  );
}

void main() {
  group('QPC V2 page frame', () {
    test('keeps the 0.65 page ratio and fits height first', () {
      final phone = mushafPageFrameSize(const Size(358, 690));
      expect(phone.width, closeTo(358, 0.01));
      expect(phone.height, closeTo(358 / 0.65, 0.01));
      expect(phone.width / phone.height, closeTo(0.65, 0.001));

      // Wide window: height is the limit, width is not filled.
      final wide = mushafPageFrameSize(const Size(900, 830));
      expect(wide.height, closeTo(830, 0.01));
      expect(wide.width, closeTo(830 * 0.65, 0.01));
      expect(wide.width, lessThan(900));
    });

    test('tablet landscape stays inside the available height', () {
      final tablet = mushafPageFrameSize(const Size(1024, 665));
      expect(tablet.height, closeTo(665, 0.01));
      expect(tablet.width, closeTo(432.25, 0.01));
    });

    test('degenerate constraints produce an empty frame', () {
      expect(mushafPageFrameSize(Size.zero), Size.zero);
      expect(mushafPageFrameSize(const Size(0, 600)), Size.zero);
      expect(
        mushafPageFrameSize(const Size(double.infinity, 600)),
        Size.zero,
      );
    });

    test('every page uses the same frame scale', () {
      final frame = mushafPageFrameSize(const Size(933, 569));
      final scale = mushafPageScaleFor(frame);
      expect(scale, closeTo(frame.width / kMushafPageLayoutWidth, 1e-9));
      // The frame is content independent: pages 1, 2, 3, 50 and 604 all use it.
      expect(mushafPageScaleFor(frame), scale);
    });
  });

  group('spread pairing', () {
    test('odd page on the right, even page on the left', () {
      expect(mushafSpreadForPage(1).rightPage, 1);
      expect(mushafSpreadForPage(1).leftPage, 2);
      expect(mushafSpreadForPage(2).rightPage, 1);
      expect(mushafSpreadForPage(2).leftPage, 2);

      expect(mushafSpreadForPage(3).pages, [3, 4]);
      expect(mushafSpreadForPage(4).pages, [3, 4]);
      expect(mushafSpreadForPage(4).rightPage, 3);
      expect(mushafSpreadForPage(4).leftPage, 4);
    });

    test('last spread is 603|604', () {
      expect(mushafSpreadForPage(603).pages, [603, 604]);
      expect(mushafSpreadForPage(604).pages, [603, 604]);
      expect(mushafSpreadForPage(604).range, (603, 604));
    });

    test('spread index maps both pages of a pair to one item', () {
      expect(mushafSpreadIndexForPage(1), 0);
      expect(mushafSpreadIndexForPage(2), 0);
      expect(mushafSpreadIndexForPage(4), 1);
      expect(mushafSpreadIndexForPage(604), 301);
      expect(kMushafSpreadCount, 302);
      expect(mushafSpreadPageForIndex(0), 1);
      expect(mushafSpreadPageForIndex(301), 603);
    });

    test('out of range pages clamp into the mushaf', () {
      expect(mushafSpreadForPage(-5).pages, [1, 2]);
      expect(mushafSpreadForPage(9999).pages, [603, 604]);
    });
  });

  group('hinge layout', () {
    test('no feature uses the default gutter', () {
      final hinge = mushafHingeLayout(
        size: const Size(933, 569),
        displayFeatures: const [],
      );
      expect(hinge.gap, kMushafSpreadGap);
      expect(hinge.leftInset, 0);
      expect(hinge.rightInset, 0);
    });

    test('flat fold reported with zero width still gets a real gap', () {
      final hinge = mushafHingeLayout(
        size: const Size(933, 569),
        displayFeatures: [_verticalFold(466.5)],
      );
      expect(hinge.gap, kMushafMinHingeGap);
      expect(hinge.leftInset, 0);
      expect(hinge.rightInset, 0);
    });

    test('hinge gap is centred on the feature', () {
      final hinge = mushafHingeLayout(
        size: const Size(933, 569),
        displayFeatures: [_verticalFold(466.5, width: 40)],
      );
      expect(hinge.gap, 40);
      expect(hinge.leftInset, 0);
      expect(hinge.rightInset, 0);

      final offset = mushafHingeLayout(
        size: const Size(933, 569),
        displayFeatures: [_verticalFold(566.5)],
      );
      expect(offset.leftInset, 200);
      expect(offset.rightInset, 0);
      expect(offset.horizontalInsets, 200);
    });

    test('horizontal fold is detected', () {
      expect(mushafHasHorizontalFold([_horizontalFold(350)]), isTrue);
      expect(mushafHasHorizontalFold([_verticalFold(466.5)]), isFalse);
      expect(
        mushafHasHorizontalFold([_horizontalFold(350), _verticalFold(466.5)]),
        isTrue,
      );
    });
  });

  group('spread gate', () {
    test('Galaxy Z Fold 8 inner (933x704, vertical fold) shows a spread', () {
      final metrics = resolveMushafSpread(
        available: const Size(933, 569),
        displayFeatures: [_verticalFold(466.5)],
        spreadEnabled: true,
      );
      expect(metrics.showSpread, isTrue, reason: metrics.reason);
      expect(metrics.pageSize.width, closeTo(369.85, 1));
      expect(metrics.pageSize.height, closeTo(569, 1));
      expect(metrics.pageSize.width / metrics.pageSize.height,
          closeTo(0.65, 0.001));
    });

    test('Fold inner with the Samsung taskbar inset keeps the spread', () {
      final metrics = resolveMushafSpread(
        available: const Size(901, 545),
        displayFeatures: [_verticalFold(450.5)],
        spreadEnabled: true,
      );
      expect(metrics.showSpread, isTrue, reason: metrics.reason);
      expect(metrics.pageSize.width, closeTo(354, 2));
      expect(metrics.pageSize.height, closeTo(545, 1));
      expect(metrics.pageSize.height, lessThanOrEqualTo(545));
    });

    test('Fold Ultra inner (955x860) shows a spread', () {
      final metrics = resolveMushafSpread(
        available: const Size(955, 725),
        displayFeatures: [_verticalFold(477.5)],
        spreadEnabled: true,
      );
      expect(metrics.showSpread, isTrue, reason: metrics.reason);
      expect(metrics.pageSize.width, greaterThan(kMushafMinSpreadPageWidth));
    });

    test('portrait Fold (horizontal fold) forces a single page', () {
      final metrics = resolveMushafSpread(
        available: const Size(704, 795),
        displayFeatures: [_horizontalFold(397.5)],
        spreadEnabled: true,
      );
      expect(metrics.showSpread, isFalse);
      expect(metrics.reason, 'horizontal fold');
    });

    test('cover screen (475x751) stays single page', () {
      final metrics = resolveMushafSpread(
        available: const Size(475, 616),
        displayFeatures: const [],
        spreadEnabled: true,
      );
      expect(metrics.showSpread, isFalse);
      expect(metrics.reason, contains('< 600'));
    });

    test('phone landscape (844x390) has no room for two pages', () {
      final metrics = resolveMushafSpread(
        available: const Size(844, 235),
        displayFeatures: const [],
        spreadEnabled: true,
      );
      expect(metrics.showSpread, isFalse);
      expect(metrics.reason, contains('page'));
    });

    test('narrow but tall windows stay single page', () {
      final metrics = resolveMushafSpread(
        available: const Size(599, 800),
        displayFeatures: const [],
        spreadEnabled: true,
      );
      expect(metrics.showSpread, isFalse);
    });

    test('setting off always renders one page', () {
      final metrics = resolveMushafSpread(
        available: const Size(933, 569),
        displayFeatures: [_verticalFold(466.5)],
        spreadEnabled: false,
      );
      expect(metrics.showSpread, isFalse);
      expect(metrics.reason, 'setting off');
      expect(metrics.pageSize.height, closeTo(569, 1));
    });
  });
}
