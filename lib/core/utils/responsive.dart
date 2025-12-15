import 'package:flutter/material.dart';

class Responsive {
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 840;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 840;
  }

  static double getContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 840) {
      return 720;
    }
    return width;
  }
}

