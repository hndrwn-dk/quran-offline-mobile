import 'package:flutter/material.dart';

/// Bottom nav and Read screen header — Al-Qur'an on rehal (Noun Project, Wendi Abi).
/// Attribution text removed from artwork; see assets/icon/ICON_CREDITS.md.
class NavReadIcon extends StatefulWidget {
  const NavReadIcon({super.key, this.selected = false, this.size});

  final bool selected;
  final double? size;

  static const idleAssetPath = 'assets/icon/nav_read_quran.png';
  static const activeAssetPath = 'assets/icon/nav_read_quran_active.png';

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
      ),
    );
  }
}
