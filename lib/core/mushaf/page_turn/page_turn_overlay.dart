import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_painter.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_controller.dart';

/// Paints the active leaf turn above the (live) spread.
///
/// The overlay is inert: drags and taps are handled by the page view so the
/// ayah recognizers below keep working. It only exists while a turn is active.
class MushafPageTurnOverlay extends StatelessWidget {
  const MushafPageTurnOverlay({
    super.key,
    required this.controller,
    required this.belowPages,
    required this.frontImage,
    required this.backImage,
    required this.background,
    required this.ink,
    this.spine = PageCurlSpine.soft,
  });

  final PageTurnController controller;
  final List<PageTurnBelowPage> belowPages;
  final ui.Image? frontImage;
  final ui.Image? backImage;
  final Color background;
  final Color ink;
  final PageCurlSpine spine;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final geometry = controller.geometry;
          if (geometry == null) return const SizedBox.shrink();
          return SizedBox.expand(
            child: CustomPaint(
              painter: PageCurlPainter(
                geometry: geometry,
                background: background,
                ink: ink,
                frontImage: frontImage,
                backImage: backImage,
                belowPages: belowPages,
                spineStyle: spine,
              ),
              isComplex: true,
              willChange: true,
            ),
          );
        },
      ),
    );
  }
}
