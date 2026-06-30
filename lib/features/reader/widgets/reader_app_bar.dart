import 'package:flutter/material.dart';

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

PreferredSizeWidget readerAppBarBottomDivider(ColorScheme colorScheme) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    ),
  );
}

Widget? readerAppBarBackButton(BuildContext context) {
  return Navigator.canPop(context) ? const BackButton() : null;
}
