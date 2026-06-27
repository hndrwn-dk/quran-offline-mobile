import 'package:flutter/material.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';

/// App bar for screens pushed from Beranda (Tentang, Pengaturan).
/// Back arrow only — no title; matches Beranda green tint when scrolling.
class SettingsMenuAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsMenuAppBar({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topTint = HomeBackdrop.topTint(colorScheme);

    return AppBar(
      automaticallyImplyLeading: showBackButton,
      backgroundColor: topTint,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
    );
  }
}
