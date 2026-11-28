import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';

/// Shared reader AppBar chrome — matches [ExploreSectionScaffold] title rhythm.
class ReaderAppBarTitleColumn extends StatelessWidget {
  const ReaderAppBarTitleColumn({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Foreground for text and icons on [AppSurfaces.tint]. The dark scheme's
/// primary is too close to its tint, so dark uses onPrimaryContainer.
Color readerOnTint(ColorScheme colorScheme) => colorScheme.onTint;

/// Soft fill behind the ayah (or Bismillah) being recited.
Color readerPlayingFill(ColorScheme colorScheme) =>
    colorScheme.brightness == Brightness.dark
        ? colorScheme.tint.withValues(alpha: 0.55)
        : colorScheme.tint;

PreferredSizeWidget readerAppBarBottomDivider(ColorScheme colorScheme) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.hairline,
    ),
  );
}

/// Text-settings action for the reader AppBar: "Aa" in a small circle.
class ReaderTextSettingsAction extends StatelessWidget {
  const ReaderTextSettingsAction({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.card,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.hairline),
          ),
          child: Text(
            'Aa',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
