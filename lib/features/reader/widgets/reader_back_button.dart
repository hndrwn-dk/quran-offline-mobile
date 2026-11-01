import 'package:flutter/material.dart';

/// Reader-family back affordance: a 48x48 dp target with the circular arrow
/// used by the Beranda cards.
///
/// It is always rendered (never `null`), so the Surah/Juz reader, the Mushaf and
/// the tablet split pane always expose a visible way back. When the screen is
/// not a pushed route (the split-pane reader), [onFallback] runs instead — the
/// reader clears its selected source and returns to the list.
class ReaderBackButton extends StatelessWidget {
  const ReaderBackButton({
    super.key,
    this.onFallback,
    this.tooltip,
    this.icon = Icons.arrow_back_rounded,
    this.minimumSize = kMinInteractiveDimension,
  });

  /// Invoked when the navigator cannot pop (embedded split-pane reader).
  final VoidCallback? onFallback;

  final String? tooltip;
  final IconData icon;
  final double minimumSize;

  /// Standard `AppBar.leading` slot with a small inset.
  static Widget appBarLeading(
    BuildContext context, {
    VoidCallback? onFallback,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: ReaderBackButton(
        onFallback: onFallback,
        tooltip: tooltip,
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.maybePop();
      return;
    }
    onFallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final label =
        tooltip ?? MaterialLocalizations.of(context).backButtonTooltip;

    final decoration = BoxDecoration(
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

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: minimumSize,
          height: minimumSize,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _handleTap(context),
              child: Center(
                child: DecoratedBox(
                  decoration: decoration,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, size: 18, color: colorScheme.primary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
