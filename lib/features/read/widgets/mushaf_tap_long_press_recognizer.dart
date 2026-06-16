import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets a single [TextSpan] respond to both tap and long-press.
class MushafTapLongPressRecognizer extends GestureRecognizer {
  MushafTapLongPressRecognizer({VoidCallback? onTap, VoidCallback? onLongPress}) {
    _tap = TapGestureRecognizer(debugOwner: this)..onTap = onTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = onLongPress;
  }

  late final TapGestureRecognizer _tap;
  late final LongPressGestureRecognizer _longPress;

  @override
  void addPointer(PointerDownEvent event) {
    _tap.addPointer(event);
    _longPress.addPointer(event);
  }

  @override
  String get debugDescription => 'mushafTapLongPress';

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}

  @override
  void addAllowedPointer(PointerDownEvent event) {}

  @override
  void dispose() {
    _tap.dispose();
    _longPress.dispose();
    super.dispose();
  }
}
