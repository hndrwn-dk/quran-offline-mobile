import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';

/// Flat card for Koleksi list rows (bookmarks, notes, highlights).
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
    final accent = accentColor;
    // Accent badges keep the item's own color; the number is the same hue
    // pulled toward the ink color so it stays readable on the soft fill.
    final badgeFill = accent?.withValues(alpha: 0.2) ??
        (selected ? colorScheme.card : null);
    final badgeTextColor = accent == null
        ? null
        : Color.lerp(accent, colorScheme.onSurface, 0.45);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
    );
    final hasArabic = arabicText != null && arabicText!.isNotEmpty;
    final hasTranslation = translation != null && translation!.isNotEmpty;
    final hasNote = noteText != null && noteText!.isNotEmpty;
    final hasTrailing = trailingAction != null;

    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: selected ? colorScheme.tint : colorScheme.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          customBorder: shape,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              selectionMode ? 8 : 18,
              hasTrailing ? 8 : 16,
              hasTrailing ? 6 : 14,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                    AppBadge(
                      label: '$surahId',
                      background: badgeFill,
                      foreground: badgeTextColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        surahName,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$ayahNo',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasTrailing)
                      trailingAction!
                    else if (showChevron && !selectionMode)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
                if (hasArabic || hasTranslation || hasNote)
                  Padding(
                    padding: EdgeInsets.only(
                      left: selectionMode ? 10 : 0,
                      right: hasTrailing ? 12 : 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasArabic) ...[
                          SizedBox(height: hasTrailing ? 2 : 8),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              arabicText!,
                              style: QuranArabicText.arabicDisplayStyle(
                                fontSize: 22,
                                color: colorScheme.onSurface,
                                height: 1.7,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                        if (hasTranslation) ...[
                          const SizedBox(height: 6),
                          Text(
                            translation!,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (hasNote) ...[
                          const SizedBox(height: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.card
                                  : colorScheme.canvas,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(
                                noteText!,
                                style: textTheme.bodyMedium?.copyWith(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
