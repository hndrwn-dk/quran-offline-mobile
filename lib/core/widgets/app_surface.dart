import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';

/// Flat card on the canvas: no border, no shadow, no gradient.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = AppTheme.cardRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return Material(
      color: color ?? colorScheme.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              customBorder: shape,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}

/// One card holding several rows, separated by inset hairlines.
class AppGroupedCard extends StatelessWidget {
  const AppGroupedCard({
    super.key,
    required this.children,
    this.dividerIndent = 16,
    this.radius = 20,
  });

  final List<Widget> children;

  /// Left inset of the hairline between rows.
  final double dividerIndent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: dividerIndent,
                color: colorScheme.hairline,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Small uppercase label above a section, with an optional trailing widget.
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Rounded tinted square holding an icon or a short label (surah number).
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    this.icon,
    this.label,
    this.size = 32,
    this.background,
    this.foreground,
  }) : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fg = foreground ?? colorScheme.onTint;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? colorScheme.tint,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.55, color: fg)
          : Text(
              label!,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
    );
  }
}

/// App bar for tab roots: one large left-aligned title, optional subtitle,
/// actions on the right. Keeps the backdrop tint, overlay style and corner arc.
class AppLargeTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const AppLargeTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  static const double _titleHeight = 60;
  static const double _subtitleHeight = 26;

  @override
  Size get preferredSize => Size.fromHeight(
        _titleHeight + (subtitle == null ? 0 : _subtitleHeight),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _titleHeight,
      centerTitle: false,
      titleSpacing: 20,
      backgroundColor: HomeBackdrop.topTint(colorScheme),
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
      flexibleSpace: HomeBackdrop.cornerArcFlexibleSpace(colorScheme),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.headlineLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      // The subtitle sits under the actions so it can use the full width.
      bottom: subtitle == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(_subtitleHeight),
              child: SizedBox(
                height: _subtitleHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      actions: actions,
    );
  }
}
