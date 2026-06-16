import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Plain cream wash background for Beranda (no dot pattern).
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key, required this.child});

  final Widget child;

  static Color topTint(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return isDark
        ? colorScheme.primary.withValues(alpha: 0.12)
        : const Color(0xFFE8EDE3);
  }

  static SystemUiOverlayStyle overlayStyle(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: topTint(colorScheme),
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final topTintColor = topTint(colorScheme);
    final bottomTint = isDark
        ? colorScheme.surface
        : colorScheme.surface.withValues(alpha: 0.98);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topTintColor, bottomTint],
        ),
      ),
      child: child,
    );
  }
}
