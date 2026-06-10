import 'package:flutter/material.dart';

/// Bottom nav and Read screen header Quran icon.
/// Icons by Freepik via Flaticon:
/// - https://www.flaticon.com/free-icon/quran_15660421 (default)
/// - https://www.flaticon.com/free-icon/quran_15660477 (active)
class NavReadIcon extends StatelessWidget {
  const NavReadIcon({super.key, this.selected = false, this.size});

  final bool selected;
  final double? size;

  static const idleAssetPath = 'assets/icon/nav_read_quran.png';
  static const activeAssetPath = 'assets/icon/nav_read_quran_active.png';

  /// Decode both bitmaps once before the nav bar is shown (reduces device flicker).
  static Future<void> precache(BuildContext context) {
    return Future.wait([
      precacheImage(const AssetImage(idleAssetPath), context),
      precacheImage(const AssetImage(activeAssetPath), context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final cacheSize = _cachePixelSize(context, resolvedSize);

    return RepaintBoundary(
      child: SizedBox(
        width: resolvedSize,
        height: resolvedSize,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            _NavReadLayer(
              assetPath: idleAssetPath,
              visible: !selected,
              size: resolvedSize,
              cacheSize: cacheSize,
            ),
            _NavReadLayer(
              assetPath: activeAssetPath,
              visible: selected,
              size: resolvedSize,
              cacheSize: cacheSize,
            ),
          ],
        ),
      ),
    );
  }

  static int _cachePixelSize(BuildContext context, double logicalSize) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * dpr).round().clamp(24, 128);
  }
}

/// Both layers stay mounted; only opacity toggles (no asset swap / fade on device).
class _NavReadLayer extends StatelessWidget {
  const _NavReadLayer({
    required this.assetPath,
    required this.visible,
    required this.size,
    required this.cacheSize,
  });

  final String assetPath;
  final bool visible;
  final double size;
  final int cacheSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          excludeFromSemantics: !visible,
        ),
      ),
    );
  }
}
