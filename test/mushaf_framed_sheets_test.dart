import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/mushaf_sheet_layout.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:quran_offline/features/read/widgets/mushaf_paper.dart';

import 'support/mushaf_real_pages.dart';

/// Fold 8 inner screen: status bar 40dp, gesture bar ~15dp.
const _foldStatusBar = 40.0;
const _foldNavBar = 15.0;

/// Compact framed AppBar (44dp toolbar + 1dp divider).
const _framedBar = 45.0;

/// 1.0.23 chrome inside the area in normal mode (see `_MushafFramedBody`),
/// banners hidden. Focus mode does not use the 1.0.23 floor.
const _legacySpreadNormal = (55.0 - _framedBar) + 6 + 61 + 2 + 4;
const _legacySingleNormal = (55.0 - _framedBar) + 20 + 61 + 10 - 4;

/// 1.0.23 measured normal-mode ayah size on the Fold.
const _baselineNormalFont = 21.3;

/// Approved focus-mode size on the Fold with outer frame + page number.
const _foldFocusFont = 26.67;

ColorScheme _scheme(String theme) => switch (theme) {
      'dark' => AppColors.darkColorScheme(),
      // No sepia theme ships yet: a sepia-seeded scheme checks that the paper
      // follows whatever tokens the scheme provides.
      'sepia' => ColorScheme.fromSeed(
          seedColor: const Color(0xFF8A6A45),
          brightness: Brightness.light,
        ),
      _ => AppColors.lightColorScheme(),
    };

class _Case {
  const _Case(this.name, this.window, this.pages, {required this.focus});

  final String name;
  final Size window;

  /// Left to right.
  final List<int> pages;
  final bool focus;

  bool get spread => pages.length == 2;

  Size get area => focus
      ? window
      : Size(
          window.width,
          window.height - _foldStatusBar - _framedBar - _foldNavBar,
        );

  double get legacyChrome => spread ? _legacySpreadNormal : _legacySingleNormal;
}

const _fold = Size(933, 704);
const _cases = [
  _Case('spread_1_2_focus', _fold, [2, 1], focus: true),
  _Case('spread_1_2_normal', _fold, [2, 1], focus: false),
  _Case('spread_3_4_focus', _fold, [4, 3], focus: true),
  _Case('spread_3_4_normal', _fold, [4, 3], focus: false),
  _Case('spread_603_604_focus', _fold, [604, 603], focus: true),
  _Case('spread_603_604_normal', _fold, [604, 603], focus: false),
  _Case('single_3_704x933_focus', Size(704, 933), [3], focus: true),
  _Case('single_3_704x933_normal', Size(704, 933), [3], focus: false),
  _Case('spread_3_4_955x860_focus', Size(955, 860), [4, 3], focus: true),
];

final Map<int, QpcV2PageContent> _contents = {};
late double _openingScale;

Future<void> _pumpCase(
  WidgetTester tester,
  _Case c,
  ColorScheme scheme, {
  GlobalKey? boundaryKey,
  double textScale = 1,
}) async {
  tester.view.physicalSize = c.area;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: mushafRenderOverrides(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: scheme, fontFamily: 'Roboto'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: RepaintBoundary(
          key: boundaryKey,
          child: MushafFramedSheets(
            pages: c.pages,
            focus: c.focus,
            legacyVerticalChrome: c.legacyChrome,
            pageBuilder: (pageNo) => MushafPageSheet(
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
}

MushafSheetLayout _layoutFor(_Case c) => c.focus
    ? resolveMushafFocusSheetLayout(area: c.area, pageCount: c.pages.length)
    : resolveMushafSheetLayout(
        area: c.area,
        pageCount: c.pages.length,
        floor: mushafLegacyTextFrame(
          area: c.area,
          pageCount: c.pages.length,
          verticalChrome: c.legacyChrome,
        ),
      );

void main() {
  setUpAll(() async {
    if (!mushafRealPagesAvailable) return;
    const pages = [1, 2, 3, 4, 603, 604];
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

  group('goldens', () {
    for (final c in _cases) {
      for (final theme in const ['light', 'dark', 'sepia']) {
        testWidgets('${c.name} $theme', (tester) async {
          await _pumpCase(tester, c, _scheme(theme));
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MushafFramedSheets),
            matchesGoldenFile('goldens/framed/${c.name}_$theme.png'),
          );
        }, skip: !mushafRealPagesAvailable);
      }
    }
  });

  group('font size', () {
    test('opening spread keeps the shared opening scale', () {
      expect(_openingScale, closeTo(1.2935, 0.0005));
    }, skip: !mushafRealPagesAvailable);

    for (final c in _cases) {
      final label =
          c.focus ? 'outer frame + number in focus' : 'rendered text >= 1.0.23';
      testWidgets('${c.name}: $label', (tester) async {
        await _pumpCase(tester, c, _scheme('light'));
        final layout = _layoutFor(c);
        for (final page in c.pages) {
          final box = tester.getSize(find.byKey(ValueKey<int>(page)));
          final font = kMushafPageFontSize * mushafPageScaleFor(box);
          if (c.focus) {
            // Same level on every spread: outer line + number, no rosettes.
            expect(layout.decor, MushafSheetDecor.outerFrame);
            expect(layout.showNumber, isTrue);
            if (c.window == _fold && c.spread) {
              expect(font, closeTo(_foldFocusFont, 0.01), reason: 'page $page');
            }
          } else {
            final floor = mushafLegacyTextFrame(
              area: c.area,
              pageCount: c.pages.length,
              verticalChrome: c.legacyChrome,
            );
            final floorFont = kMushafPageFontSize * mushafPageScaleFor(floor);
            expect(font, greaterThanOrEqualTo(floorFont - 0.01),
                reason: 'page $page');
            if (c.window == _fold && c.spread) {
              expect(font, greaterThanOrEqualTo(_baselineNormalFont),
                  reason: 'page $page');
            }
          }
        }
        // Both pages of a spread render at one size.
        if (c.spread) {
          final a = tester.getSize(find.byKey(ValueKey<int>(c.pages[0])));
          final b = tester.getSize(find.byKey(ValueKey<int>(c.pages[1])));
          expect(a.width, closeTo(b.width, 1e-6));
          expect(a.height, closeTo(b.height, 1e-6));
        }
      }, skip: !mushafRealPagesAvailable);
    }
  });

  group('ink geometry', () {
    for (final (c, textScale) in [
      for (final c in _cases) (c, 1.0),
      // The Fold 8 ships with a 0.9 system font scale.
      for (final c in _cases.where((c) => c.window == _fold)) (c, 0.9),
    ]) {
      testWidgets('${c.name} x$textScale: mirrored margins and clearance',
          (tester) async {
        final key = GlobalKey();
        final scheme = _scheme('light');
        await _pumpCase(
          tester,
          c,
          scheme,
          boundaryKey: key,
          textScale: textScale,
        );
        final layout = _layoutFor(c);
        final palette = MushafPaperPalette.of(scheme);
        final margins = <(double, double)>[];
        for (var i = 0; i < c.pages.length; i++) {
          final sheet = layout.sheets[i];
          final text = layout.texts[i];
          // Above the page number band.
          final ink = await inkBounds(
            tester,
            find.byKey(key),
            ink: scheme.onSurface,
            background: palette.sheet,
            within: Rect.fromLTRB(
              sheet.left + 1,
              sheet.top + 1,
              sheet.right - 1,
              text.bottom + 1,
            ),
          );
          expect(ink, isNotNull, reason: 'page ${c.pages[i]}');
          final toLeft = ink!.left - sheet.left;
          final toRight = sheet.right - ink.right;
          // Text-to-spine == text-to-outer-edge (±2dp).
          expect((toLeft - toRight).abs(), lessThanOrEqualTo(2),
              reason: 'page ${c.pages[i]} left $toLeft right $toRight');
          margins.add((toLeft, toRight));

          if (layout.decor.hasOuterFrame) {
            final depth = layout.decor.decorationDepth;
            expect(toLeft - depth, greaterThanOrEqualTo(kMushafInkClearance),
                reason: 'left clearance page ${c.pages[i]}');
            expect(toRight - depth, greaterThanOrEqualTo(kMushafInkClearance),
                reason: 'right clearance page ${c.pages[i]}');
            expect(ink.top - sheet.top - depth,
                greaterThanOrEqualTo(kMushafInkClearance),
                reason: 'top clearance page ${c.pages[i]}');
          }
        }
        // 3|4 lines are equally wide: the margins match across the spread.
        if (c.spread && c.pages.contains(3)) {
          expect((margins[0].$1 - margins[1].$1).abs(), lessThanOrEqualTo(2));
        }
      }, skip: !mushafRealPagesAvailable);
    }
  });
}
