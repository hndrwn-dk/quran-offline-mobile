import 'package:flutter/material.dart';
import 'package:quran_offline/core/share/verse_share_content.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

/// Branded share card (RepaintBoundary → PNG). Cream backdrop, white inset, Play link.
class VerseShareCard extends StatelessWidget {
  const VerseShareCard({
    super.key,
    required this.content,
  });

  final VerseShareContent content;

  static const Color _creamTop = Color(0xFFE8EDE3);
  static const Color _creamBottom = Color(0xFFF4F6F0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final translation = content.translation;
    final primary = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: kVerseShareCardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_creamTop, _creamBottom],
          ),
          border: Border.all(
            color: primary.withValues(alpha: 0.18),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SharePatternPainter(
                    color: primary.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(content: content, primary: primary),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _ArabicBlock(
                              content: content,
                              isLight: isLight,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              content.referenceLine,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                          if (translation != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              '"$translation"',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Footer(content: content, primary: primary),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 3,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.content,
    required this.primary,
  });

  final VerseShareContent content;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.menu_book_rounded, size: 20, color: primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quran Offline',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.15,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.getShareHeader(content.appLanguage),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.content,
    required this.primary,
  });

  final VerseShareContent content;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shop_outlined, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.getSharePlayStoreCta(content.appLanguage),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  content.playStoreDisplay,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontSize: 10,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArabicBlock extends StatelessWidget {
  const _ArabicBlock({
    required this.content,
    required this.isLight,
  });

  final VerseShareContent content;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const fontSize = kVerseShareCardArabicFontSize;
    final defaultColor = colorScheme.onSurface;

    if (content.showTajweed && content.tajweedHtml != null) {
      return Localizations.override(
        context: context,
        locale: const Locale('ar'),
        child: TajweedText(
          tajweedHtml: content.tajweedHtml!,
          fontSize: fontSize,
          defaultColor: defaultColor,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          height: 1.85,
          replaceWaslaWithAlif: true,
          isLightTheme: true,
        ),
      );
    }

    return Localizations.override(
      context: context,
      locale: const Locale('ar'),
      child: Text(
        content.plainArabic,
        style: TajweedText.arabicDisplayStyle(
          fontSize: fontSize,
          color: defaultColor,
          height: 1.85,
          isLightTheme: isLight,
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SharePatternPainter extends CustomPainter {
  _SharePatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const radii = [56.0, 44.0, 38.0, 52.0];
    final offsets = [
      Offset(size.width * 0.88, size.height * 0.08),
      Offset(size.width * 0.06, size.height * 0.22),
      Offset(size.width * 0.78, size.height * 0.72),
      Offset(size.width * 0.12, size.height * 0.88),
    ];
    for (var i = 0; i < radii.length; i++) {
      canvas.drawCircle(offsets[i], radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SharePatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
