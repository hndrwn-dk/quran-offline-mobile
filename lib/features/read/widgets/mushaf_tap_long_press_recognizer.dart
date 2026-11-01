import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets a single [TextSpan] respond to both tap and long-press.
///
/// Extends [LongPressGestureRecognizer] (instead of a bare [GestureRecognizer])
/// so Flutter's paragraph semantics can describe the span; a custom recognizer
/// type trips a debug assertion as soon as accessibility semantics is enabled.
/// The tap half is a regular [TapGestureRecognizer] competing in the same arena.
class MushafTapLongPressRecognizer extends LongPressGestureRecognizer {
  MushafTapLongPressRecognizer({
    VoidCallback? onTap,
    GestureLongPressCallback? onLongPress,
    super.duration,
    super.debugOwner,
    super.allowedButtonsFilter,
  }) {
    this.onLongPress = onLongPress;
    _tap = TapGestureRecognizer()..onTap = onTap;
  }

  late final TapGestureRecognizer _tap;

  @override
  void addPointer(PointerDownEvent event) {
    _tap.addPointer(event);
    super.addPointer(event);
  }

  @override
  String get debugDescription => 'mushafTapLongPress';

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }
}
