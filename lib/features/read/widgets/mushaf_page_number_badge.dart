import 'package:flutter/material.dart';

/// Decorative page marker at the bottom of a Mushaf page view.
class MushafPageNumberBadge extends StatelessWidget {
  const MushafPageNumberBadge({
    super.key,
    required this.pageNo,
    this.totalPages = 604,
  });

  final int pageNo;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final progress = (pageNo / totalPages).clamp(0.0, 1.0);

    final ringTrack = colorScheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.55 : 0.85,
    );
    final ringProgress = colorScheme.primary.withValues(alpha: isDark ? 0.75 : 0.55);
    final fillTop = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
        : colorScheme.surface.withValues(alpha: 0.94);
    final fillBottom = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : const Color(0xFFE8EDE3).withValues(alpha: 0.45);
    final accentLine = colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.24);

    const outerSize = 44.0;
    const innerSize = 34.0;

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OrnamentLine(color: accentLine, width: 22),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: isDark ? 0.18 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              width: outerSize,
              height: outerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: outerSize,
                    height: outerSize,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: ringTrack,
                      color: ringProgress,
                    ),
                  ),
                  Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [fillTop, fillBottom],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pageNo',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrnamentLine extends StatelessWidget {
  const _OrnamentLine({
    required this.color,
    this.width = 22,
  });

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0), color],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
        Container(
          width: width,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
    );
  }
}
