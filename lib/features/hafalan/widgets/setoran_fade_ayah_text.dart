import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';
import 'package:quran_offline/features/hafalan/models/setoran_ayah_fade_state.dart';

/// Sketsa fade: teks Arab samar → jelas (benar) atau samar merah (salah).
class SetoranFadeAyahText extends StatelessWidget {
  const SetoranFadeAyahText({
    super.key,
    required this.arabic,
    this.tajweedHtml,
    required this.fontSize,
    required this.state,
    this.isLightTheme = false,
    this.compact = false,
    this.listeningForCheck = false,
  });

  final String arabic;
  final String? tajweedHtml;
  final double fontSize;
  final SetoranAyahFadeState state;
  final bool isLightTheme;
  final bool compact;
  final bool listeningForCheck;

  static const double ghostOpacity = 0.14;
  static const double listeningOpacity = 0.38;
  static const double errorOpacity = 0.95;
  static const Duration revealDuration = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = switch (state) {
      SetoranAyahFadeState.error => colorScheme.error,
      SetoranAyahFadeState.revealed => colorScheme.onSurface,
      SetoranAyahFadeState.ghost => colorScheme.onSurface,
    };
    final opacity = switch (state) {
      SetoranAyahFadeState.revealed => 1.0,
      SetoranAyahFadeState.error => errorOpacity,
      SetoranAyahFadeState.ghost =>
        listeningForCheck ? listeningOpacity : ghostOpacity,
    };
    final fontWeight = switch (state) {
      SetoranAyahFadeState.revealed => FontWeight.w700,
      SetoranAyahFadeState.error => FontWeight.w700,
      SetoranAyahFadeState.ghost => FontWeight.w400,
    };

    final child = tajweedHtml != null && tajweedHtml!.isNotEmpty
        ? TajweedText(
            tajweedHtml: tajweedHtml!,
            fontSize: fontSize,
            defaultColor: baseColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            isLightTheme: isLightTheme,
            height: compact ? 1.5 : 1.7,
            fontWeight: fontWeight,
          )
        : Text(
            arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TajweedText.arabicDisplayStyle(
              fontSize: fontSize,
              color: baseColor,
              height: compact ? 1.5 : 1.7,
              isLightTheme: isLightTheme,
              fontWeight: fontWeight,
            ),
          );

    return AnimatedOpacity(
      opacity: opacity,
      duration: revealDuration,
      curve: Curves.easeOut,
      child: child,
    );
  }
}
