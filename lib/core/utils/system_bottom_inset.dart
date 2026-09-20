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
