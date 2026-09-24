import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cream wash for tab roots, plus a header-only right-corner hairline arc.
///
/// The arc lives in [AppBar.flexibleSpace] so it never crosses body cards.
/// Not used on Mushaf / verse reader.
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key, required this.child});

  final Widget child;

  /// Canvas "header saja": 180px SVG, top -88, right -88, circle at 90.
  static const double _arcCenterFromTop = 2;
  static const double _arcCenterFromRight = 2;

  static Color topTint(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    if (!isDark) return const Color(0xFFE8EDE3);
    // Blend onto surface so Scaffold/AppBar stay opaque. A 12% primary
    // wash as backgroundColor composites during Android page transitions
    // and flashes the previous Jelajahi list in dark mode.
    return Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.12),
      colorScheme.surface,
    );
  }

  /// Icon contrast only. Android 15 deprecated bar colours, and the app bar
  /// already paints [topTint] behind the status bar in edge-to-edge.
  static SystemUiOverlayStyle overlayStyle(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  /// Hairline arcs clipped to the AppBar. Body stays clean.
  static Widget cornerArcFlexibleSpace(ColorScheme colorScheme) {
    return IgnorePointer(
      child: CustomPaint(
        key: const Key('home_corner_arc_bar'),
        painter: _HomeCornerArcPainter(
          innerColor: _arcInnerColor(colorScheme),
          outerColor: _arcOuterColor(colorScheme),
          centerY: _arcCenterFromTop,
          centerFromRight: _arcCenterFromRight,
        ),
      ),
    );
  }

  static Color _arcInnerColor(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return colorScheme.outline.withValues(alpha: isDark ? 0.40 : 0.32);
  }

  static Color _arcOuterColor(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return colorScheme.outline.withValues(alpha: isDark ? 0.24 : 0.18);
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

class _HomeCornerArcPainter extends CustomPainter {
  const _HomeCornerArcPainter({
    required this.innerColor,
    required this.outerColor,
    required this.centerY,
    required this.centerFromRight,
  });

  final Color innerColor;
  final Color outerColor;
  final double centerY;
  final double centerFromRight;

  static const double _stroke = 1;
  static const double _innerRadius = 62;
  static const double _outerRadius = 82;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - centerFromRight, centerY);
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..isAntiAlias = true;
    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..isAntiAlias = true;
    canvas.drawCircle(center, _innerRadius, innerPaint);
    canvas.drawCircle(center, _outerRadius, outerPaint);
  }

  @override
  bool shouldRepaint(_HomeCornerArcPainter oldDelegate) {
    return oldDelegate.innerColor != innerColor ||
        oldDelegate.outerColor != outerColor ||
        oldDelegate.centerY != centerY ||
        oldDelegate.centerFromRight != centerFromRight;
  }
}
