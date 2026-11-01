import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/mushaf_sheet_layout.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/widgets/mushaf_page_frame.dart';
import 'package:quran_offline/features/read/widgets/mushaf_paper.dart';
import 'package:quran_offline/features/read/widgets/qpc_v2_mushaf_text.dart';

/// One Mushaf page rendered in the fixed QPC V2 frame.
///
/// The page is laid out once at the reference size and scaled uniformly, so two
/// sheets side by side always share the same text size.
class MushafPageSheet extends StatelessWidget {
  const MushafPageSheet({
    super.key,
    required this.content,
    required this.colorScheme,
    required this.ayahKeys,
    this.openingPageScale = 1.0,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
  });

  final QpcV2PageContent content;
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;

  /// Opening-page (1-2) scale; 1 for normal pages.
  final double openingPageScale;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;

  @override
  Widget build(BuildContext context) {
    return MushafPageFrame(
      child: QpcV2MushafText(
        content: content,
        contentWidth: kMushafPageLayoutWidth,
        fontSize: kMushafPageFontSize,
        pageGrid: true,
        openingPageScale: openingPageScale,
        colorScheme: colorScheme,
        ayahKeys: ayahKeys,
        onAyahTap: onAyahTap,
        onAyahLongPress: onAyahLongPress,
        onBismillahTap: onBismillahTap,
        onBismillahLongPress: onBismillahLongPress,
      ),
    );
  }
}

/// Framed Mushaf (>= 600dp): one or two paper sheets on a desk.
///
/// [pages] are left to right (a spread is `[even, odd]`). Each page's text box
/// is placed by [resolveMushafSheetLayout], which never makes the text smaller
/// than the 1.0.23 framed layout ([legacyVerticalChrome] describes how much of
/// this area that layout spent on chrome), or in [focus] mode by
/// [resolveMushafFocusSheetLayout]. Layout direction is forced LTR so
/// the even page is always the left sheet regardless of the app language.
class MushafFramedSheets extends StatelessWidget {
  const MushafFramedSheets({
    super.key,
    required this.pages,
    required this.pageBuilder,
    required this.legacyVerticalChrome,
    this.focus = false,
    this.wantNumber = true,
    this.pageNumberLabel,
  });

  final List<int> pages;
  final Widget Function(int pageNo) pageBuilder;
  final double legacyVerticalChrome;

  /// Bars hidden: fixed outer frame + page number on every spread.
  final bool focus;
  final bool wantNumber;
  final String Function(int pageNo)? pageNumberLabel;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final palette = MushafPaperPalette.of(Theme.of(context).colorScheme);
    final spread = pages.length == 2;

    return ColoredBox(
      color: palette.desk,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final area = constraints.biggest;
          if (!area.isFinite || area.isEmpty) return const SizedBox.shrink();

          final hinge = spread
              ? mushafSheetHinge(
                  size: area,
                  displayFeatures: media.displayFeatures,
                )
              : const MushafHingeLayout(gap: 0);
          final legacyHinge = spread
              ? mushafHingeLayout(
                  size: area,
                  displayFeatures: media.displayFeatures,
                )
              : const MushafHingeLayout();
          // A side cutout is mirrored so both outer edges keep one clearance.
          final sideInset = math.max(
            media.viewPadding.left,
            media.viewPadding.right,
          );
          final layout = focus
              ? resolveMushafFocusSheetLayout(
                  area: area,
                  pageCount: pages.length,
                  hinge: hinge,
                  sideInset: sideInset,
                )
              : resolveMushafSheetLayout(
                  area: area,
                  pageCount: pages.length,
                  floor: mushafLegacyTextFrame(
                    area: area,
                    pageCount: pages.length,
                    verticalChrome: legacyVerticalChrome,
                    hinge: legacyHinge,
                  ),
                  hinge: hinge,
                  sideInset: sideInset,
                  wantNumber: wantNumber,
                );
          if (kDebugMode) {
            debugPrint('[MushafSheets] area=$area $layout');
          }

          final sides = [
            for (var i = 0; i < pages.length; i++)
              () {
                // Single page: odd pages are right-hand pages of the book.
                final onRight = spread ? i == 1 : pages[i].isOdd;
                return MushafSheetSide(
                  rect: layout.sheets[i],
                  onRight: onRight,
                  stackEdges: mushafStackEdgeCount(
                    pageNo: pages[i],
                    onRight: onRight,
                  ),
                );
              }(),
          ];

          return Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: MushafPaperPainter(
                        sheets: sides,
                        palette: palette,
                        showStack: layout.showStack,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: MushafFramePainter(
                        sheets: layout.sheets,
                        decor: layout.decor,
                        palette: palette,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < pages.length; i++)
                  Positioned.fromRect(
                    key: ValueKey<int>(pages[i]),
                    rect: layout.texts[i],
                    child: pageBuilder(pages[i]),
                  ),
                if (layout.showNumber)
                  for (var i = 0; i < pages.length; i++)
                    Positioned(
                      left: layout.sheets[i].left,
                      width: layout.sheets[i].width,
                      top: layout.texts[i].bottom +
                          layout.inkBelowText +
                          kMushafSheetNumberGap,
                      height: kMushafSheetNumberHeight,
                      child: Center(
                        child: MushafSheetPageNumber(
                          pageNo: pages[i],
                          color: palette.number,
                          semanticsLabel: pageNumberLabel?.call(pages[i]),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
