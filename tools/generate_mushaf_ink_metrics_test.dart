// Regenerates lib/core/mushaf/qpc_v2_page_ink_metrics.dart.
//
//   flutter test tools/generate_mushaf_ink_metrics_test.dart
//
// Renders every QPC V2 page in the 15-row page grid (needs the bundled data,
// `scripts/qo.sh sync`) and measures the real ink:
// * the horizontal shift that centres each page's ayah ink on the page box;
// * the largest ink overhang past the box (top, bottom, sides) once centred,
//   which the framed sheet margins reserve so frame lines never touch ink.
//
// This file is not part of the normal `test/` suite.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/features/read/widgets/qpc_v2_mushaf_text.dart';

import '../test/support/mushaf_real_pages.dart';

const _outPath = 'lib/core/mushaf/qpc_v2_page_ink_metrics.dart';
const _pad = 40.0;
const _ratio = 4.0;

/// Ink box of the rendered page in reference units, relative to the page box,
/// without the ink-centring shift.
Future<Rect> _measure(
  WidgetTester tester,
  QpcV2PageContent content,
  double openingScale, {
  required bool withHeaders,
}) async {
  final key = GlobalKey();
  // Surah headers use primary: paint them white to measure ayah ink only.
  final scheme = ColorScheme.fromSeed(seedColor: Colors.green).copyWith(
    surface: Colors.white,
    onSurface: Colors.black,
    primary: withHeaders ? Colors.black : Colors.white,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: mushafRenderOverrides(),
      child: MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(_pad),
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: kMushafPageLayoutWidth,
              height: kMushafPageLayoutHeight,
              child: QpcV2MushafText(
                content: content,
                contentWidth: kMushafPageLayoutWidth,
                fontSize: kMushafPageFontSize,
                pageGrid: true,
                openingPageScale: openingScale,
                inkCentering: false,
                colorScheme: scheme,
                ayahKeys: Map<String, GlobalKey>.of(const {}),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final render = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await tester.runAsync(() => render.toImage(pixelRatio: _ratio));
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final bytes = data!.buffer.asUint8List();
  final w = image!.width, h = image.height;
  if (Platform.environment['INK_DEBUG'] == '${content.pageNumber}') {
    final png = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    File('build/ink_debug_${content.pageNumber}_$withHeaders.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  }
  var minX = w, minY = h, maxX = -1, maxY = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      // Ink: dark in every channel (skips faint colour-layer hairlines).
      if (bytes[i + 3] > 200 &&
          bytes[i] < 150 &&
          bytes[i + 1] < 150 &&
          bytes[i + 2] < 150) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  image.dispose();
  return Rect.fromLTRB(
    minX / _ratio - _pad,
    minY / _ratio - _pad,
    (maxX + 1) / _ratio - _pad,
    (maxY + 1) / _ratio - _pad,
  );
}

String _fmt(double v) => v.toStringAsFixed(2);

void main() {
  final only = int.tryParse(Platform.environment['INK_DEBUG'] ?? '');
  final pages = only != null
      ? [only]
      : List<int>.generate(kMushafTotalPages, (i) => i + 1);

  setUpAll(() => loadMushafTestFonts(pages));

  testWidgets('generate', (tester) async {
    tester.view.physicalSize = const Size(
      kMushafPageLayoutWidth + _pad * 2,
      kMushafPageLayoutHeight + _pad * 2,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final openingScale = computeOpeningPageScale(
      lines: [loadRealPage(1), loadRealPage(2)].expand(
        (page) => page.lines
            .where((l) => l.isAyah && l.glyphText.isNotEmpty)
            .map((l) => (
                  glyphText: l.glyphText,
                  fontFamily: page.fontFamily,
                  justify: false,
                )),
      ),
    );

    final shifts = <double>[];
    var top = 0.0, bottom = 0.0, side = 0.0;
    for (final page in pages) {
      final content = loadRealPage(page);
      final scale = page <= 2 ? openingScale : 1.0;
      final ayah = await _measure(tester, content, scale, withHeaders: false);
      // Move the ink centre onto the box centre (quarter-unit steps).
      final raw = ((kMushafPageLayoutWidth - ayah.right) - ayah.left) / 2;
      final shift = (raw * 4).round() / 4;
      shifts.add(shift);

      final all = await _measure(tester, content, scale, withHeaders: true);
      top = math.max(top, -all.top);
      bottom = math.max(bottom, all.bottom - kMushafPageLayoutHeight);
      side = math.max(side, -(ayah.left + shift));
      side = math.max(side, ayah.right + shift - kMushafPageLayoutWidth);
    }
    _write(shifts, top, bottom, side);
    // ignore: avoid_print
    print('overhang top ${_fmt(top)} bottom ${_fmt(bottom)} side ${_fmt(side)}'
        '; max |shift| ${_fmt(shifts.map((s) => s.abs()).reduce(math.max))}');
  });
}

void _write(List<double> shifts, double top, double bottom, double side) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE - do not edit by hand.')
    ..writeln('// Regenerate with: '
        'flutter test tools/generate_mushaf_ink_metrics_test.dart')
    ..writeln('//')
    ..writeln('// Real ink of every QPC V2 page in the 15-row page grid, in '
        'reference units')
    ..writeln('// (the ${kMushafPageLayoutWidth.round()}-wide page box), '
        'rounded up by a quarter unit.')
    ..writeln()
    ..writeln('/// Largest ink extent above the page box (any page).')
    ..writeln('const double kQpcV2InkOverhangTop = ${_fmt(top + 0.25)};')
    ..writeln()
    ..writeln('/// Largest ink extent below the page box (any page).')
    ..writeln('const double kQpcV2InkOverhangBottom = ${_fmt(bottom + 0.25)};')
    ..writeln()
    ..writeln(
        '/// Largest ink extent past either side once centred (any page).')
    ..writeln('const double kQpcV2InkOverhangSide = ${_fmt(side + 0.25)};')
    ..writeln()
    ..writeln('/// Horizontal shift that centres the ayah ink of each page.')
    ..writeln('const List<double> _shifts = [');
  for (var i = 0; i < shifts.length; i += 10) {
    final row = shifts.sublist(i, math.min(i + 10, shifts.length));
    buffer.writeln('  ${row.map(_fmt).join(', ')},');
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('/// Ink-centring shift for [pageNumber] (0 outside 1..604).')
    ..writeln('double qpcV2PageInkShift(int pageNumber) =>')
    ..writeln('    pageNumber >= 1 && pageNumber <= _shifts.length')
    ..writeln('        ? _shifts[pageNumber - 1]')
    ..writeln('        : 0;');
  File(_outPath).writeAsStringSync(buffer.toString());
}
