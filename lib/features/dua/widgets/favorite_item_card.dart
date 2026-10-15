import 'package:flutter/material.dart';
import 'package:quran_offline/core/explore/favorite_display.dart';
import 'package:quran_offline/features/dua/explore_icons.dart';
import 'package:quran_offline/features/dua/widgets/arabic_snippet.dart';

class FavoriteItemCard extends StatelessWidget {
  const FavoriteItemCard({
    super.key,
    required this.display,
    required this.removeLabel,
    this.compact = false,
    this.onTap,
    this.onRemove,
  });

  final FavoriteDisplay display;
  final String removeLabel;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = _accentColors(display.accent, colorScheme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KindTile(
                  section: display.iconSection,
                  background: colors.background,
                  foreground: colors.foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display.eyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        display.title,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ArabicSnippet(
                        arabic: display.catalogArabic,
                        surah: display.snippetSurah,
                        ayah: display.snippetAyah,
                        large: display.catalogArabic != null,
                      ),
                      if (display.qsLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          display.qsLabel!,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact)
                  Semantics(
                    button: true,
                    label: removeLabel,
                    child: IconButton(
                      tooltip: removeLabel,
                      onPressed: onRemove,
                      style: IconButton.styleFrom(
                        fixedSize: const Size(44, 44),
                        minimumSize: const Size(44, 44),
                        maximumSize: const Size(44, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        Icons.favorite,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.section,
    required this.background,
    required this.foreground,
  });

  final String section;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final asset = ExploreIcons.hubSectionAsset(section);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: asset != null
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                color: foreground,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => Icon(
                  ExploreIcons.hubSection(section),
                  size: 22,
                  color: foreground,
                ),
              ),
            )
          : Icon(
              ExploreIcons.hubSection(section),
              size: 22,
              color: foreground,
            ),
    );
  }
}

({Color background, Color foreground}) _accentColors(
  FavoriteAccent accent,
  ColorScheme scheme,
) {
  return switch (accent) {
    FavoriteAccent.green => (
        background: scheme.primaryContainer,
        foreground: scheme.primary,
      ),
    FavoriteAccent.sand => (
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
    FavoriteAccent.blue => (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
  };
}
