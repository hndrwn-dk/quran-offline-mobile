import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_controller.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';

const _leftRect = Rect.fromLTWH(0, 0, 400, 600);
const _rightRect = Rect.fromLTWH(424, 0, 400, 600);

PageTurnPlan _plan(PageTurnDirection direction, {int visiblePage = 1}) =>
    pageTurnPlan(
      visiblePage: visiblePage,
      spread: true,
      direction: direction,
    )!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PageTurnController controller;
  final completed = <PageTurnPlan>[];
  var cancelled = 0;

  setUp(() {
    completed.clear();
    cancelled = 0;
    controller = PageTurnController(
      vsync: const TestVSync(),
      duration: Duration.zero,
      playDuration: Duration.zero,
    );
    controller.onCompleted = completed.add;
    controller.onCancelled = () => cancelled++;
    controller.setPageAreas(
      leftRect: _leftRect,
      rightRect: _rightRect,
      hingeGap: 24,
      spread: true,
    );
  });

  tearDown(() => controller.dispose());

  test('a drag that is let go early springs back and keeps the page', () async {
    final plan = _plan(PageTurnDirection.forward);
    controller.beginDrag(plan);
    expect(controller.isActive, isTrue);
    controller.updateDrag(totalDeltaX: 80, pageWidth: 400);
    expect(controller.progress, closeTo(0.2, 1e-9));

    await controller.endDrag(velocityX: 0);
    expect(controller.isActive, isFalse);
    expect(controller.progress, 0);
    expect(completed, isEmpty);
    expect(cancelled, 1);
  });

  test('past 35% the released leaf completes', () async {
    final plan = _plan(PageTurnDirection.forward);
    controller.beginDrag(plan);
    controller.updateDrag(totalDeltaX: 200, pageWidth: 400);
    await controller.endDrag(velocityX: 0);
    expect(controller.isActive, isFalse);
    expect(completed, [plan]);
    expect(cancelled, 0);
  });

  test('a fast fling completes below the progress threshold', () async {
    final plan = _plan(PageTurnDirection.forward);
    controller.beginDrag(plan);
    controller.updateDrag(totalDeltaX: 40, pageWidth: 400);
    await controller.endDrag(velocityX: 1200);
    expect(completed, [plan]);
  });

  test('backward drags use the mirrored velocity sign', () async {
    final plan = _plan(PageTurnDirection.backward, visiblePage: 3);
    controller.beginDrag(plan);
    controller.updateDrag(totalDeltaX: -40, pageWidth: 400);
    expect(controller.progress, closeTo(0.1, 1e-9));
    await controller.endDrag(velocityX: 1200); // wrong direction
    expect(completed, isEmpty);

    controller.beginDrag(plan);
    controller.updateDrag(totalDeltaX: -40, pageWidth: 400);
    await controller.endDrag(velocityX: -900);
    expect(completed, [plan]);
  });

  test('drag progress clamps at both ends, never overscrolls', () async {
    final plan = _plan(PageTurnDirection.forward);
    controller.beginDrag(plan);
    controller.updateDrag(totalDeltaX: -400, pageWidth: 400);
    expect(controller.progress, 0);
    controller.updateDrag(totalDeltaX: 400, pageWidth: 400);
    expect(controller.progress, 1);
    controller.updateDrag(totalDeltaX: 800, pageWidth: 400);
    expect(controller.progress, 1);
    await controller.endDrag(velocityX: 0);
    expect(completed, [plan]);
  });

  test('tilt is stored for the shader and clamped', () async {
    controller.beginDrag(_plan(PageTurnDirection.forward), tilt: 0.5);
    expect(controller.tilt, 0.5);
    controller.updateDrag(totalDeltaX: 100, pageWidth: 400, tilt: 2.3);
    expect(controller.tilt, 1);
    await controller.play(_plan(PageTurnDirection.forward), tilt: -3);
    expect(controller.tilt, -1);
  });

  test('cancel aborts without landing on another page', () async {
    final plan = _plan(PageTurnDirection.forward);
    controller.beginDrag(plan);
    controller.updateDrag(totalDeltaX: 300, pageWidth: 400);
    controller.cancel();
    expect(controller.isActive, isFalse);
    expect(completed, isEmpty);
    expect(cancelled, 1);
  });

  test('play() is the non interactive turn used by recitation follow',
      () async {
    final plan = _plan(PageTurnDirection.forward);
    await controller.play(plan);
    expect(completed, [plan]);
    expect(controller.isActive, isFalse);
  });

  test('geometry follows the stored page areas and direction', () {
    controller.beginDrag(_plan(PageTurnDirection.forward));
    expect(controller.geometry!.frontRect, _leftRect);
    controller.updateDrag(totalDeltaX: 400, pageWidth: 400);
    expect(controller.geometry!.progress, 1);
    expect(controller.geometry!.backRect, _rightRect);
  });

  test('without page areas there is nothing to paint', () {
    final empty = PageTurnController(
      vsync: const TestVSync(),
      duration: Duration.zero,
    );
    addTearDown(empty.dispose);
    empty.beginDrag(_plan(PageTurnDirection.forward));
    expect(empty.geometry, isNull);
  });
}
