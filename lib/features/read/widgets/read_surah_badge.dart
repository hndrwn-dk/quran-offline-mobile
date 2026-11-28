import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';

/// 32px rounded tinted square badge for Baca surah index rows.
class ReadSurahBadge extends StatelessWidget {
  const ReadSurahBadge({super.key, required this.surahId});

  final int surahId;

  static const double size = 32;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: '$surahId', size: size);
  }
}
