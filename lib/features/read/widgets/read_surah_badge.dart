import 'package:flutter/material.dart';

/// 32px rounded-square badge for Baca surah index rows.
class ReadSurahBadge extends StatelessWidget {
  const ReadSurahBadge({super.key, required this.surahId});

  final int surahId;

  static const double size = 32;
  static const double radius = 8;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$surahId',
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
