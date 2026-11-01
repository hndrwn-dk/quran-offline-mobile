import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/widgets/mushaf_page_frame.dart';
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

/// A physical mushaf spread: even page on the left, odd page on the right.
///
/// The gutter is placed on a reported fold/hinge and never lets text sit on the
/// crease. Layout direction is forced LTR so the even page is always the left
/// half regardless of the app language.
class MushafSpreadRow extends StatelessWidget {
  const MushafSpreadRow({
    super.key,
    required this.left,
    required this.right,
    required this.hinge,
    this.spine = MushafSpineStyle.softShade,
  });

  final Widget left;
  final Widget right;
  final MushafHingeLayout hinge;
  final MushafSpineStyle spine;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(
        left: hinge.leftInset,
        right: hinge.rightInset,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(child: left),
            SizedBox(
              width: hinge.gap,
              child: switch (spine) {
                MushafSpineStyle.none => null,
                MushafSpineStyle.softShade => Center(
                    child: Container(
                      width: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            ink.withValues(alpha: 0),
                            ink.withValues(alpha: 0.04),
                            ink.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
              },
            ),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }
}

/// How the gutter between the two pages of a spread is drawn.
enum MushafSpineStyle {
  /// Empty gutter.
  none,

  /// Very soft 12dp shade (<= 4% ink), like the fold of a printed book.
  softShade,
}

