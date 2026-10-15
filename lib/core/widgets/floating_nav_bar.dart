import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_offline/core/utils/system_bottom_inset.dart';

/// Space tab content needs so it clears the floating pill.
///
/// Uses [MediaQueryData.viewPadding], so a [Scaffold] that already reports the
/// bar through [MediaQueryData.padding] does not add the height twice.
double floatingNavBarBottomPadding(MediaQueryData mediaQuery) {
  if (imeVisible(mediaQuery)) return 0;
  return FloatingNavBar.barHeight +
      FloatingNavBar.bottomMargin +
      mediaQuery.viewPadding.bottom;
}

/// Insets [child] by [floatingNavBarBottomPadding].
class FloatingNavBarInset extends StatelessWidget {
  const FloatingNavBarInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = floatingNavBarBottomPadding(MediaQuery.of(context));
    if (bottom <= 0) return child;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: child,
    );
  }
}

class FloatingNavDestination {
  const FloatingNavDestination({
    this.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Key? key;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Pill navigation bar. Colors come from [ColorScheme].
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  static const double barHeight = 64;
  static const double bottomMargin = 12;
  static const double horizontalMargin = 16;
  static const double itemExtent = 48;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          horizontalMargin,
          0,
          horizontalMargin,
          bottomMargin,
        ),
        child: DecoratedBox(
          key: const Key('floating_nav_capsule'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color:
                    colorScheme.shadow.withValues(alpha: isDark ? 0.45 : 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: barHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final selectedMax = math.max(
                      itemExtent,
                      constraints.maxWidth -
                          itemExtent * (destinations.length - 1),
                    );
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var index = 0;
                            index < destinations.length;
                            index++)
                          _FloatingNavButton(
                            destination: destinations[index],
                            selected: index == selectedIndex,
                            maxWidth: index == selectedIndex
                                ? selectedMax
                                : itemExtent,
                            onTap: () {
                              if (index != selectedIndex) {
                                HapticFeedback.selectionClick();
                              }
                              onDestinationSelected(index);
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavButton extends StatelessWidget {
  const _FloatingNavButton({
    required this.destination,
    required this.selected,
    required this.maxWidth,
    required this.onTap,
  });

  final FloatingNavDestination destination;
  final bool selected;
  final double maxWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      key: destination.key,
      label: destination.label,
      selected: selected,
      button: true,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                minHeight: FloatingNavBar.itemExtent,
                maxHeight: FloatingNavBar.itemExtent,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: FloatingNavBar.itemExtent,
                    width: selected ? null : FloatingNavBar.itemExtent,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 14 : 0,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected
                              ? destination.selectedIcon
                              : destination.icon,
                          size: selected ? 20 : 22,
                          color: foreground,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            destination.label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: foreground,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
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
