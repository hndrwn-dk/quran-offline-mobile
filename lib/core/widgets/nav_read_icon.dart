import 'package:flutter/material.dart';

/// Bottom nav and Read screen header — Al-Qur'an on rehal (Noun Project, Wendi Abi).
/// Attribution text removed from artwork; see assets/icon/ICON_CREDITS.md.
class NavReadIcon extends StatefulWidget {
  const NavReadIcon({super.key, this.selected = false, this.size});

  final bool selected;
  final double? size;

  static const idleAssetPath = 'assets/icon/nav_read_quran.png';
  static const activeAssetPath = 'assets/icon/nav_read_quran_active.png';

  /// Single source of truth for display and [precache] decode size.
  static double resolveLogicalSize(BuildContext context, {double? size}) {
    return size ?? IconTheme.of(context).size ?? 24.0;
  }

  static Future<void> precache(BuildContext context, {double? size}) {
    final logical = resolveLogicalSize(context, size: size);
    final cachePx =
        (logical * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Future.wait([
      precacheImage(
        ResizeImage(
          const AssetImage(idleAssetPath),
          width: cachePx,
        ),
        context,
      ),
      precacheImage(
        ResizeImage(
          const AssetImage(activeAssetPath),
          width: cachePx,
        ),
        context,
      ),
    ]);
  }

  @override
  State<NavReadIcon> createState() => _NavReadIconState();
}

class _NavReadIconState extends State<NavReadIcon> {
  static const _idleKey = ValueKey<String>('nav_read_idle');
  static const _activeKey = ValueKey<String>('nav_read_active');

  @override
  Widget build(BuildContext context) {
    final resolvedSize = NavReadIcon.resolveLogicalSize(
      context,
      size: widget.size,
    );

    return RepaintBoundary(
      child: SizedBox(
        width: resolvedSize,
        height: resolvedSize,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            _NavReadLayer(
              key: _idleKey,
              assetPath: NavReadIcon.idleAssetPath,
              offstage: widget.selected,
              size: resolvedSize,
            ),
            _NavReadLayer(
              key: _activeKey,
              assetPath: NavReadIcon.activeAssetPath,
              offstage: !widget.selected,
              size: resolvedSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavReadLayer extends StatelessWidget {
  const _NavReadLayer({
    super.key,
    required this.assetPath,
    required this.offstage,
    required this.size,
  });

  final String assetPath;
  final bool offstage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tint = iconTheme.color ?? scheme.onSurface;
    final cachePx =
        (size * MediaQuery.devicePixelRatioOf(context)).ceil();

    return Offstage(
      offstage: offstage,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        color: tint,
        colorBlendMode: BlendMode.srcIn,
        excludeFromSemantics: offstage,
        cacheWidth: cachePx,
      ),
    );
  }
}
