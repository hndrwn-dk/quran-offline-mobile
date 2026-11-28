import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';

/// Flat grouped card for Juz / Mushaf section surah lists on the canvas.
class ReadGroupedSurahCard extends StatelessWidget {
  const ReadGroupedSurahCard({super.key, required this.child});

  final Widget child;

  static const double radius = 20;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// One row of a lazily built grouped card: the first row rounds the top
/// corners, the last rounds the bottom, and rows after the first carry the
/// hairline, so a long sliver list reads as a single card.
class ReadGroupedSurahTile extends StatelessWidget {
  const ReadGroupedSurahTile({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.child,
    this.inkKey,
    this.onTap,
  });

  final bool isFirst;
  final bool isLast;
  final Widget child;
  final Key? inkKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const corner = Radius.circular(ReadGroupedSurahCard.radius);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? corner : Radius.zero,
        bottom: isLast ? corner : Radius.zero,
      ),
    );

    return Material(
      color: colorScheme.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: inkKey,
        onTap: onTap,
        customBorder: shape,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFirst) const ReadGroupedSurahDivider(),
            child,
          ],
        ),
      ),
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
      indent: 16,
      color: colorScheme.hairline,
    );
  }
}
