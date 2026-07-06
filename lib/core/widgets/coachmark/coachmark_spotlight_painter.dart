import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/coachmark/coachmark_style.dart';

/// Dims the screen with a rounded-rect cut-out around the target widget.
class CoachmarkSpotlightPainter extends CustomPainter {
  CoachmarkSpotlightPainter({required this.targetRect});

  final Rect targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holeRect = targetRect.inflate(CoachmarkStyle.spotlightPadding);
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          holeRect,
          const Radius.circular(CoachmarkStyle.spotlightBorderRadius),
        ),
      );

    final dimPath = Path.combine(PathOperation.difference, overlayPath, holePath);
    canvas.drawPath(
      dimPath,
      Paint()..color = CoachmarkStyle.overlay,
    );
  }

  @override
  bool shouldRepaint(CoachmarkSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
