import 'package:flutter/material.dart';

/// Section header link: primary text + chevron (gaya 2).
class HomeSectionChevronLink extends StatelessWidget {
  const HomeSectionChevronLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Text(
            '$label \u203A',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

/// Label + optional trailing chevron link on one row.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.linkLabel,
    this.onLinkPressed,
  });

  final String title;
  final String? linkLabel;
  final VoidCallback? onLinkPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (linkLabel != null && onLinkPressed != null)
            HomeSectionChevronLink(
              label: linkLabel!,
              onPressed: onLinkPressed!,
            ),
        ],
      ),
    );
  }
}
