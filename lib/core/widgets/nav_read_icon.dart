import 'package:flutter/material.dart';

/// Bottom nav and Read screen header Quran icon.
/// Icons by Freepik via Flaticon:
/// - https://www.flaticon.com/free-icon/quran_15660421 (default)
/// - https://www.flaticon.com/free-icon/quran_15660477 (active)
class NavReadIcon extends StatefulWidget {
  const NavReadIcon({super.key, this.selected = false, this.size});

  final bool selected;
  final double? size;

  static const idleAssetPath = 'assets/icon/nav_read_quran.png';
  static const activeAssetPath = 'assets/icon/nav_read_quran_active.png';

  /// Decode both bitmaps before the nav bar is shown (call and await before Home).
  static Future<void> precache(BuildContext context) {
    return Future.wait([
      precacheImage(const AssetImage(idleAssetPath), context),
      precacheImage(const AssetImage(activeAssetPath), context),
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
    final iconTheme = IconTheme.of(context);
    final resolvedSize = widget.size ?? iconTheme.size ?? 24;

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

/// Both layers stay mounted; [Offstage] toggles paint (no opacity / asset swap).
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
    return Offstage(
      offstage: offstage,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: offstage,
      ),
    );
  }
}
