import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/mushaf/mushaf_sheet_layout.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_snapshot.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:quran_offline/features/read/widgets/mushaf_paper.dart';

import 'support/mushaf_real_pages.dart';

/// Leaf snapshots must carry the page's text, never blank paper.
///
/// Spreads are rendered like the framed reader (focus mode, Fold 8 inner),
/// rasterized, cropped per sheet, and the text box is measured against the
/// sheet's PAPER colour.
const _fold = Size(933, 704);
const _spreads = [
  [2, 1],
  [4, 3],
  [50, 49],
  [52, 51],
  [604, 603],
];
const _leafPages = [2, 3, 50, 51, 603, 604];

final Map<int, QpcV2PageContent> _contents = {};
late double _openingScale;

class _Captured {
  _Captured(this.images, this.layout);

  final List<ui.Image> images;
  final MushafSheetLayout layout;
}

Future<_Captured> _capture(
  WidgetTester tester,
  List<int> pages,
  ColorScheme scheme, {
  bool blank = false,
}) async {
  tester.view.physicalSize = _fold;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  MushafSheetLayout? layout;
  await tester.pumpWidget(
    ProviderScope(
      overrides: mushafRenderOverrides(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: scheme, fontFamily: 'Roboto'),
        home: RepaintBoundary(
          key: key,
          child: MushafFramedSheets(
            pages: pages,
            focus: true,
            legacyVerticalChrome: 0,
            onLayout: (l) => layout = l,
            pageBuilder: (pageNo) => blank
                ? const SizedBox.expand()
                : MushafPageSheet(
                    content: _contents[pageNo]!,
                    openingPageScale: pageNo <= 2 ? _openingScale : 1,
                    colorScheme: scheme,
                    ayahKeys: Map<String, GlobalKey>.of(const {}),
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final images = await tester.runAsync(
    () async => captureSheetSnapshots(boundary, layout!.sheets, pixelRatio: 1),
  );
  return _Captured(images!, layout!);
}

Future<double> _textInk(
  WidgetTester tester,
  _Captured captured,
  int index,
  Color paper,
) async {
  final text = captured.layout.texts[index]
      .shift(-captured.layout.sheets[index].topLeft);
  final ink = await tester.runAsync(
    () => snapshotInkCoverage(captured.images[index], paper: paper, within: text),
  );
  return ink!;
}

void main() {
  setUpAll(() async {
    if (!mushafRealPagesAvailable) return;
    final pages = {for (final s in _spreads) ...s, 1};
    await loadMushafTestFonts(pages);
    for (final page in pages) {
      _contents[page] = loadRealPage(page);
    }
    _openingScale = computeOpeningPageScale(
      lines: [_contents[1]!, _contents[2]!].expand(
        (page) => page.lines
            .where((l) => l.isAyah && l.glyphText.isNotEmpty)
            .map((l) => (
                  glyphText: l.glyphText,
                  fontFamily: page.fontFamily,
                  justify: false,
                )),
      ),
    );
  });

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    final scheme =
        dark ? AppColors.darkColorScheme() : AppColors.lightColorScheme();
    final paper = MushafPaperPalette.of(scheme).sheet;

    for (final spread in _spreads) {
      testWidgets('spread ${spread.reversed.join('|')} sheets have ink ($theme)',
          (tester) async {
        final captured = await _capture(tester, spread, scheme);
        for (var i = 0; i < spread.length; i++) {
          final page = spread[i];
          final image = captured.images[i];
          final sheet = captured.layout.sheets[i];
          // Cropped to the sheet, at the requested pixel ratio.
          expect(image.width, closeTo(sheet.width, 2));
          expect(image.height, closeTo(sheet.height, 2));
          if (!_leafPages.contains(page)) continue;
          final ink = await _textInk(tester, captured, i, paper);
          expect(
            ink,
            greaterThan(kPageSnapshotMinInk),
            reason: 'p$page snapshot is blank paper ($theme): ink $ink',
          );
        }
        for (final image in captured.images) {
          image.dispose();
        }
      }, skip: !mushafRealPagesAvailable);
    }

    testWidgets('blank sheets measure as blank ($theme)', (tester) async {
      final captured = await _capture(tester, [4, 3], scheme, blank: true);
      for (var i = 0; i < 2; i++) {
        final ink = await _textInk(tester, captured, i, paper);
        expect(ink, lessThan(kPageSnapshotMinInk / 10));
      }
      for (final image in captured.images) {
        image.dispose();
      }
    }, skip: !mushafRealPagesAvailable);
  }
}
