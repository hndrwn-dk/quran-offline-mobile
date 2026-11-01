import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';

Future<void> _loadSurahFont() async {
  final loader = FontLoader('SurahNameV2')
    ..addFont(rootBundle.load('assets/fonts/surah_name_v2.ttf'));
  await loader.load();
}

/// Renders the glyph inside one QPC row slot and returns its painted height.
Future<double> _glyphHeightInSlot(
  WidgetTester tester, {
  required double pageWidth,
  required double slotHeight,
  required double slotWidthFactor,
  int surahId = 2,
  double mushafFontSize = kMushafPageFontSize,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: pageWidth,
            height: slotHeight,
            child: SurahNameMushafGlyph(
              surahId: surahId,
              mushafFontSize: mushafFontSize,
              slotWidthFactor: slotWidthFactor,
              maxHeight: slotHeight,
              verticalPadding: 0,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);

  final box = tester.getRect(find.byType(FittedBox));
  expect(box.height, lessThanOrEqualTo(slotHeight + 0.01));
  expect(box.width, lessThanOrEqualTo(pageWidth + 0.01));
  return box.height;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadSurahFont();
  });

  testWidgets('surah glyph fits a full QPC row slot on page 2', (tester) async {
    await _glyphHeightInSlot(
      tester,
      pageWidth: kMushafPageLayoutWidth,
      slotHeight: kMushafPageRowHeight * 0.92,
      slotWidthFactor: 0.68,
    );
  });

  testWidgets('surah glyph fits on every screen size', (tester) async {
    // Phone, Fold inner, tablet landscape, cover screen.
    for (final pageWidth in [358.0, 370.0, 432.0, 400.0]) {
      await _glyphHeightInSlot(
        tester,
        pageWidth: pageWidth,
        slotHeight: kMushafPageRowHeight * 0.92,
        slotWidthFactor: 0.68,
      );
    }
  });

  testWidgets('wide slot cannot grow past the max height cap', (tester) async {
    // Legacy call site: 50% page width slot, 54dp cap from mushafFontSize 38.
    final height = await _glyphHeightInSlot(
      tester,
      pageWidth: 900,
      slotHeight: (38 * 1.55).clamp(44.0, 54.0),
      slotWidthFactor: 0.5,
      mushafFontSize: 38,
    );
    expect(height, lessThanOrEqualTo(54.01));
  });

  testWidgets('narrow page keeps the glyph inside the width', (tester) async {
    await _glyphHeightInSlot(
      tester,
      pageWidth: 240,
      slotHeight: kMushafPageRowHeight * 0.92,
      slotWidthFactor: 0.68,
    );
  });
}
