import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/features/read/widgets/mushaf_turn_stage.dart';

/// Turn stage behaviour with plain coloured pages.
///
/// The host test has no GPU shader, so every turn here takes the slide
/// fallback; the thresholds, bounds, directions and tap zones are the same
/// code paths the curl uses.
const _size = Size(400, 600);

class _Harness {
  final List<int> changes = [];
  final List<int> toggles = [];
  int? ready;
}

Widget _page(int index, _Harness h, {required bool ready}) {
  return Builder(
    builder: (context) {
      final slot = MushafTurnScope.maybeOf(context);
      if (ready) slot?.pageReady(index + 1);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final turned = slot?.handleTap(d.globalPosition) ?? false;
          if (!turned) h.toggles.add(index);
        },
        child: MushafTurnRegion(
          child: ColoredBox(
            color: Colors.primaries[index % Colors.primaries.length],
            child: Center(child: Text('page $index')),
          ),
        ),
      );
    },
  );
}

Future<_Harness> _pump(
  WidgetTester tester, {
  int initial = 5,
  int count = 10,
  MushafTurnStyle style = MushafTurnStyle.curl,
  bool ready = true,
}) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final h = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      home: MushafTurnStage(
        itemCount: count,
        initialIndex: initial,
        spread: false,
        style: style,
        paperColor: Colors.white,
        itemBuilder: (context, index) => _page(index, h, ready: ready),
        onIndexChanged: (index, {required programmatic}) =>
            h.changes.add(index),
      ),
    ),
  );
  await tester.pump();
  return h;
}

Future<void> _drag(WidgetTester tester, double dx, {double speed = 200}) async {
  await tester.timedDrag(
    find.byType(MushafTurnStage),
    Offset(dx, 0),
    Duration(milliseconds: (dx.abs() / speed * 1000).round()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a drag to the RIGHT turns to the next page (RTL)', (t) async {
    final h = await _pump(t);
    await _drag(t, 300);
    expect(h.changes, [6]);
    expect(find.text('page 6'), findsOneWidget);
  });

  testWidgets('a drag to the LEFT turns back', (t) async {
    final h = await _pump(t);
    await _drag(t, -300);
    expect(h.changes, [4]);
  });

  testWidgets('a short slow drag springs back without a page change',
      (t) async {
    final h = await _pump(t);
    // 25% of the width, released slowly: below the 35% commit.
    await _drag(t, 100, speed: 100);
    expect(h.changes, isEmpty);
    expect(find.text('page 5'), findsOneWidget);
  });

  testWidgets('past the commit threshold the turn completes', (t) async {
    final h = await _pump(t);
    await _drag(t, 170, speed: 100); // 42%
    expect(h.changes, [6]);
  });

  testWidgets('a fling completes a short drag', (t) async {
    final h = await _pump(t);
    await t.fling(find.byType(MushafTurnStage), const Offset(60, 0), 1500);
    await t.pumpAndSettle();
    expect(h.changes, [6]);
  });

  testWidgets('at the first page a backward drag does nothing', (t) async {
    final h = await _pump(t, initial: 0);
    await t.timedDrag(
      find.byType(MushafTurnStage),
      const Offset(-300, 0),
      const Duration(milliseconds: 600),
    );
    // Nothing moves, even mid-drag: no item is offset or clipped.
    expect(t.getTopLeft(find.text('page 0')).dx,
        closeTo(_size.width / 2 - t.getSize(find.text('page 0')).width / 2, 1));
    await t.pumpAndSettle();
    expect(h.changes, isEmpty);
  });

  testWidgets('at the last page a forward drag does nothing', (t) async {
    final h = await _pump(t, initial: 9);
    await _drag(t, 300);
    expect(h.changes, isEmpty);
    expect(find.text('page 9'), findsOneWidget);
  });

  group('tap zones', () {
    testWidgets('left edge turns forward, right edge back', (t) async {
      final h = await _pump(t);
      await t.tapAt(const Offset(20, 300));
      await t.pumpAndSettle();
      expect(h.changes, [6]);
      await t.tapAt(Offset(_size.width - 20, 300));
      await t.pumpAndSettle();
      expect(h.changes, [6, 5]);
      expect(h.toggles, isEmpty);
    });

    testWidgets('the middle toggles the bars', (t) async {
      final h = await _pump(t);
      await t.tapAt(const Offset(200, 300));
      await t.pumpAndSettle();
      expect(h.changes, isEmpty);
      expect(h.toggles, [5]);
    });

    testWidgets('edge taps at a bound do nothing (and keep the bars)',
        (t) async {
      final h = await _pump(t, initial: 0);
      await t.tapAt(Offset(_size.width - 20, 300));
      await t.pumpAndSettle();
      expect(h.changes, isEmpty);
      expect(h.toggles, isEmpty);
    });
  });

  testWidgets('Tanpa turns instantly', (t) async {
    final h = await _pump(t, style: MushafTurnStyle.none);
    await t.timedDrag(
      find.byType(MushafTurnStage),
      const Offset(80, 0),
      const Duration(milliseconds: 300),
    );
    await t.pump();
    expect(h.changes, [6]);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('pages that never painted still turn (slide fallback)',
      (t) async {
    final h = await _pump(t, ready: false);
    await _drag(t, 300);
    expect(h.changes, [6]);
  });

  testWidgets('programmatic neighbour turns animate, far ones jump', (t) async {
    final controller = MushafTurnController();
    t.view.physicalSize = _size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final changes = <(int, bool)>[];
    final h = _Harness();
    await t.pumpWidget(
      MaterialApp(
        home: MushafTurnStage(
          controller: controller,
          itemCount: 10,
          initialIndex: 5,
          spread: false,
          style: MushafTurnStyle.curl,
          paperColor: Colors.white,
          itemBuilder: (context, index) => _page(index, h, ready: true),
          onIndexChanged: (index, {required programmatic}) =>
              changes.add((index, programmatic)),
        ),
      ),
    );
    controller.animateTo(6);
    await t.pump(const Duration(milliseconds: 100));
    // Mid-turn the page has not changed yet.
    expect(changes, isEmpty);
    await t.pumpAndSettle();
    expect(changes, [(6, true)]);
    controller.animateTo(2);
    await t.pump();
    expect(changes.last, (2, true));
  });

  testWidgets('a second edge tap mid-turn chains one more turn', (t) async {
    final h = await _pump(t);
    await t.tapAt(const Offset(20, 300));
    await t.pump(const Duration(milliseconds: 50));
    await t.tapAt(const Offset(20, 300));
    await t.pump(const Duration(milliseconds: 50));
    await t.tapAt(const Offset(20, 300)); // only one is queued
    await t.pumpAndSettle();
    expect(h.changes, [6, 7]);
  });
}
