import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';

/// Fixed-aspect QPC V2 page frame.
///
/// The child is always laid out in the fixed reference box
/// ([kMushafPageLayoutWidth] x [kMushafPageLayoutHeight]) and then uniformly
/// scaled into the frame, so lines, ayah markers and justification are the same
/// on every screen — only the scale changes. A page is never stretched to the
/// full width of a wide window.
class MushafPageFrame extends StatelessWidget {
  const MushafPageFrame({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        final frame = mushafPageFrameSize(available);
        if (frame.isEmpty) {
          return const SizedBox.shrink();
        }
        if (kDebugMode) {
          debugPrint(
            '[MushafFrame] avail=${available.width.toStringAsFixed(1)}x'
            '${available.height.toStringAsFixed(1)} '
            '${frame.width.toStringAsFixed(1)}x'
            '${frame.height.toStringAsFixed(1)} '
            'scale=${mushafPageScaleFor(frame).toStringAsFixed(3)} '
            'font=${(kMushafPageFontSize * mushafPageScaleFor(frame)).toStringAsFixed(2)}dp',
          );
        }
        return Center(
          child: SizedBox.fromSize(
            size: frame,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: alignment,
              child: SizedBox(
                width: kMushafPageLayoutWidth,
                height: kMushafPageLayoutHeight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
