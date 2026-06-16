import 'package:flutter/material.dart';

/// Onboarding-style circular arrow — icon only, no label.
class HomeCircleArrowButton extends StatelessWidget {
  const HomeCircleArrowButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.semanticsLabel,
    /// Frosted circle on soft gradient cards (e.g. Lanjutkan baca).
    this.onTintedCard = false,
  });

  final VoidCallback onPressed;
  final String? tooltip;
  final String? semanticsLabel;
  final bool onTintedCard;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final BoxDecoration decoration;
    final Color iconColor;

    if (onTintedCard) {
      decoration = BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
      iconColor = colorScheme.primary;
    } else {
      decoration = BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: isDark ? 0.55 : 0.85,
        ),
        shape: BoxShape.circle,
      );
      iconColor = colorScheme.onPrimaryContainer;
    }

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: DecoratedBox(
          decoration: decoration,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.arrow_forward_rounded, size: 18, color: iconColor),
          ),
        ),
      ),
    );

    final iconTheme = IconTheme(
      data: IconThemeData(color: iconColor),
      child: button,
    );

    Widget child = iconTheme;
    if (semanticsLabel != null) {
      child = Semantics(
        button: true,
        label: semanticsLabel,
        child: child,
      );
    }
    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

/// Text + arrow row CTA (e.g. Buka catatan).
class HomeArrowCta extends StatelessWidget {
  const HomeArrowCta({
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
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
