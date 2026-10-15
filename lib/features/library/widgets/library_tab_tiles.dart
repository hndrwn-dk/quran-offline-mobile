import 'package:flutter/material.dart';

class LibraryTabTiles extends StatelessWidget {
  const LibraryTabTiles({
    super.key,
    required this.selectedIndex,
    required this.counts,
    required this.labels,
    required this.icons,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<int> counts;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _Tile(
                index: i,
                selected: i == selectedIndex,
                count: counts[i],
                label: labels[i],
                icon: icons[i],
                onTap: () => onChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.index,
    required this.selected,
    required this.count,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final int count;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.onPrimary : colorScheme.onSurface;
    final muted = selected
        ? colorScheme.onPrimary.withValues(alpha: 0.85)
        : colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? colorScheme.primary
          : colorScheme.surface.withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colorScheme.onPrimary : colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                '$count',
                key: Key('library-count-$index'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
