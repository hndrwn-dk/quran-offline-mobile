import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Bottom inset for scrollable / fixed chrome drawn under system nav bars.
///
/// Uses the larger of [MediaQueryData.viewPadding] and [MediaQueryData.padding]
/// so content clears gesture/nav bars under [SystemUiMode.edgeToEdge] even when
/// [padding] is temporarily reduced (e.g. keyboard).
double systemBottomInset(MediaQueryData mediaQuery) {
  return math.max(mediaQuery.viewPadding.bottom, mediaQuery.padding.bottom);
}

/// True when the software keyboard is open.
///
/// A focused [TextField] on Android 15+ can report a small [viewInsets] bottom
/// without showing the IME. Treating any `viewInsets.bottom > 0` as a keyboard
/// hides the home [NavigationBar] on the search tab. Keyboards are much taller
/// than gesture/nav bars (~48).
bool imeVisible(MediaQueryData mediaQuery) {
  final inset = mediaQuery.viewInsets.bottom;
  if (inset <= 0) return false;
  final chrome = systemBottomInset(mediaQuery);
  return inset > math.max(chrome, 80);
}
