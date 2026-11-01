import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/widgets/mushaf_page_frame.dart';

Future<void> _pumpFrame(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: MushafPageFrame(
        child: SizedBox.expand(child: ColoredBox(color: Color(0xFF000000))),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('phone: page fills the width inside a 0.65 frame',
      (tester) async {
    await _pumpFrame(tester, const Size(390, 844));

    final frame = tester.getSize(find.byType(FittedBox));
    expect(frame.width, closeTo(390, 0.01));
    expect(frame.height, closeTo(390 / kMushafPageAspectRatio, 0.01));
    expect(frame.width / frame.height, closeTo(0.65, 0.001));
    expect(frame.height, lessThanOrEqualTo(844));
  });

  testWidgets('wide window: page is height limited and not full width',
      (tester) async {
    await _pumpFrame(tester, const Size(900, 1000));

    final frame = tester.getSize(find.byType(FittedBox));
    expect(frame.height, closeTo(1000, 0.01));
    expect(frame.width, closeTo(650, 0.01));
    expect(frame.width, lessThan(900));

    // Centred inside the window.
    final box = tester.getRect(find.byType(FittedBox));
    expect(box.left, closeTo(900 - box.right, 0.01));
    expect(box.left, greaterThan(0));
  });

  testWidgets('fold inner screen keeps one fixed scale for both pages',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 933,
          height: 569,
          child: Row(
            children: const [
              Expanded(child: MushafPageFrame(child: SizedBox.expand())),
              Expanded(child: MushafPageFrame(child: SizedBox.expand())),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final frames = tester.widgetList(find.byType(MushafPageFrame));
    expect(frames.length, 2);

    final sizes = [
      tester.getSize(find.byType(FittedBox).at(0)),
      tester.getSize(find.byType(FittedBox).at(1)),
    ];
    expect(sizes.length, 2);
    expect(sizes.first, sizes.last);
    expect(sizes.first.width / sizes.first.height, closeTo(0.65, 0.001));
  });

  testWidgets('zero constraints render nothing instead of throwing',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 0,
          height: 0,
          child: MushafPageFrame(child: SizedBox.expand()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
