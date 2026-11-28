import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/features/dua/explore_icons.dart';

/// Hub landing row: tinted icon, title, count + hint, chevron.
class ExploreHubSectionCard extends StatelessWidget {
  const ExploreHubSectionCard({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.countLabel,
    required this.hint,
    required this.onTap,
  });

  final String sectionKey;
  final String title;
  final String countLabel;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _IconBox(
                  assetPath: ExploreIcons.hubSectionAsset(sectionKey),
                  icon: ExploreIcons.hubSection(sectionKey),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$countLabel · $hint',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Topic row for drill-down lists (mockup phase 2).
class ExploreTopicCard extends StatelessWidget {
  const ExploreTopicCard({
    super.key,
    required this.title,
    required this.refLabel,
    required this.onTap,
    this.isFavorite = false,
    this.isFirst = true,
    this.isLast = true,
  });

  final String title;
  final String refLabel;
  final VoidCallback onTap;
  final bool isFavorite;

  /// Position inside a grouped card; a lone row is a full card.
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ExploreGroupedRow(
      isFirst: isFirst,
      isLast: isLast,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        refLabel,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFavorite) ...[
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 22,
                ),
              ],
            ),
        ),
      ),
    );
  }
}

/// One row of a grouped card that is built lazily by a list: the first row
/// rounds the top corners, the last the bottom ones, with a hairline between.
/// A lone row ([isFirst] and [isLast]) is a full flat card.
class ExploreGroupedRow extends StatelessWidget {
  const ExploreGroupedRow({
    super.key,
    required this.child,
    this.onTap,
    this.isFirst = true,
    this.isLast = true,
    this.dividerIndent = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const radius = Radius.circular(20);
    return Material(
      color: colorScheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? radius : Radius.zero,
          bottom: isLast ? radius : Radius.zero,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isFirst)
            Divider(
              height: 1,
              thickness: 1,
              indent: dividerIndent,
              color: colorScheme.hairline,
            ),
          InkWell(onTap: onTap, child: child),
        ],
      ),
    );
  }
}


/// Featured category row — taller hero card for editorial picks (e.g. Sains cosmos).
class ExploreFeaturedCategoryCard extends StatelessWidget {
  const ExploreFeaturedCategoryCard({
    super.key,
    this.assetPath,
    required this.icon,
    required this.title,
    required this.countLabel,
    required this.hint,
    required this.featuredLabel,
    required this.onTap,
  });

  final String? assetPath;
  final IconData icon;
  final String title;
  final String countLabel;
  final String hint;
  final String featuredLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconBox(
                      assetPath: assetPath,
                      icon: icon,
                      colorScheme: colorScheme,
                      size: 48,
                    ),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.tint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          featuredLabel,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onTint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$countLabel · $hint',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Category row for child hubs — same full-width layout as [ExploreHubSectionCard].
class ExploreCategoryCard extends StatelessWidget {
  const ExploreCategoryCard({
    super.key,
    this.assetPath,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String? assetPath;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _IconBox(
                  assetPath: assetPath,
                  icon: icon,
                  colorScheme: colorScheme,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    this.assetPath,
    required this.icon,
    required this.colorScheme,
    this.size = 40,
  });

  final String? assetPath;
  final IconData icon;
  final ColorScheme colorScheme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inset = size * 0.18;
    final imageLogical = size - (inset * 2);
    final cachePx =
        (imageLogical * MediaQuery.devicePixelRatioOf(context)).ceil();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.tint,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: assetPath != null
          ? Padding(
              padding: EdgeInsets.all(inset),
              child: Image.asset(
                assetPath!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                color: colorScheme.onTint,
                colorBlendMode: BlendMode.srcIn,
                cacheWidth: cachePx,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  size: size * 0.5,
                  color: colorScheme.onTint,
                ),
              ),
            )
          : Icon(
              icon,
              size: size * 0.5,
              color: colorScheme.onTint,
            ),
    );
  }
}
