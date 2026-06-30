import 'package:flutter/material.dart';

/// Premium flat card for Koleksi list rows (bookmarks, notes, highlights).
class LibraryItemCard extends StatelessWidget {
  const LibraryItemCard({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.ayahNo,
    required this.onTap,
    this.onLongPress,
    this.accentColor,
    this.arabicText,
    this.translation,
    this.noteText,
    this.selected = false,
    this.selectionMode = false,
    this.onSelectionChanged,
    this.trailingAction,
    this.showChevron = true,
    this.marginBottom = 8,
  });

  final int surahId;
  final String surahName;
  final int ayahNo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color? accentColor;
  final String? arabicText;
  final String? translation;
  final String? noteText;
  final bool selected;
  final bool selectionMode;
  final ValueChanged<bool?>? onSelectionChanged;
  final Widget? trailingAction;
  final bool showChevron;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final badgeFill = accentColor != null
        ? accentColor!.withValues(alpha: 0.18)
        : colorScheme.surfaceContainerHighest;
    final badgeBorder = accentColor ?? colorScheme.outlineVariant.withValues(alpha: 0.35);
    final badgeTextColor =
        accentColor ?? colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                  : colorScheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.45)
                    : colorScheme.outlineVariant.withValues(alpha: 0.55),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectionMode) ...[
                    Checkbox(
                      value: selected,
                      onChanged: onSelectionChanged,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badgeFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: badgeBorder,
                        width: accentColor != null ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$surahId',
                      style: textTheme.labelMedium?.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                surahName,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '$ayahNo',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (arabicText != null && arabicText!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              arabicText!,
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'UthmanicHafsV22',
                                fontFamilyFallback: const ['UthmanicHafs'],
                                color: colorScheme.onSurface,
                                height: 1.55,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                        if (translation != null && translation!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            translation!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (noteText != null && noteText!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Text(
                                noteText!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.45,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailingAction != null)
                    trailingAction!
                  else if (showChevron && !selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 6),
                      child: Icon(
                        Icons.chevron_right,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
