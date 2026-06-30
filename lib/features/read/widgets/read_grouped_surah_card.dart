import 'package:flutter/material.dart';

/// Elevated grouped card for Juz / Mushaf section surah lists on cream backdrop.
class ReadGroupedSurahCard extends StatelessWidget {
  const ReadGroupedSurahCard({super.key, required this.child});

  final Widget child;

  static BoxDecoration decoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration standaloneDecoration(ColorScheme colorScheme) {
    return decoration(colorScheme);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: decoration(colorScheme),
      child: child,
    );
  }
}

/// Divider between surah rows inside a grouped card.
class ReadGroupedSurahDivider extends StatelessWidget {
  const ReadGroupedSurahDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}
