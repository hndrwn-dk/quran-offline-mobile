import 'package:flutter/material.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_fatihah_page.dart';

/// Dev spike: Mushaf sample — app Unicode vs QPC V2 Madinah glyphs.
class MushafFontCompareScreen extends StatelessWidget {
  const MushafFontCompareScreen({super.key});

  static const _unicodeFontSize = 24.0;
  static const _glyphFontSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mushaf compare — Ali \'Imran 1-9'),
      ),
      body: FutureBuilder<QpcV2SamplePage>(
        future: QpcV2SamplePage.loadAliImran1To9(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data halaman Mushaf.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            );
          }

          final page = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Halaman 50 Mushaf Madinah 1421H — Ali \'Imran 1-9. '
                'Atas: font Unicode default app. Bawah: glyph QPC V2 (QUL #249, font p50-v2).',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              _InfoNote(colorScheme: colorScheme, textTheme: textTheme),
              const SizedBox(height: 20),
              _MushafPanel(
                title: 'APP DEFAULT — Uthmanic Hafs V22 (Unicode)',
                subtitle: 'text_qpc_hafs, baris seperti layout Mushaf',
                child: _MushafPageBody(
                  page: page,
                  fontFamily: QuranFonts.uthmanicHafsV22,
                  fontSize: _unicodeFontSize,
                  useGlyphs: false,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _MushafPanel(
                title: 'MADINAH QPC V2 — QUL #249 (glyph p50-v2)',
                subtitle: 'code_v2 per kata, font halaman 50',
                child: _MushafPageBody(
                  page: page,
                  fontFamily: QuranFonts.qpcV2Page50,
                  fontSize: _glyphFontSize,
                  useGlyphs: true,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Text(
          'QPC V2 membutuhkan font berbeda per halaman (604 file). '
          'Spike ini hanya memuat halaman 50 + Ali \'Imran 1-9. '
          'Glyph code_v2 dari layout Mushaf Madinah (mushaf=1).',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _MushafPanel extends StatelessWidget {
  const _MushafPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MushafPageBody extends StatelessWidget {
  const _MushafPageBody({
    required this.page,
    required this.fontFamily,
    required this.fontSize,
    required this.useGlyphs,
    required this.color,
  });

  final QpcV2SamplePage page;
  final String fontFamily;
  final double fontSize;
  final bool useGlyphs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            for (final line in page.lines) ...[
              _MushafLineView(
                line: line,
                fontFamily: fontFamily,
                fontSize: fontSize,
                useGlyphs: useGlyphs,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MushafLineView extends StatelessWidget {
  const _MushafLineView({
    required this.line,
    required this.fontFamily,
    required this.fontSize,
    required this.useGlyphs,
    required this.color,
  });

  final QpcV2MushafLine line;
  final String fontFamily;
  final double fontSize;
  final bool useGlyphs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!line.isAyah || line.words.isEmpty) {
      return const SizedBox.shrink();
    }

    final text = useGlyphs ? line.glyphText : line.unicodeText;
    final textAlign = line.centered ? TextAlign.center : TextAlign.justify;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: useGlyphs
                ? null
                : const [QuranFonts.uthmanicHafsV22, 'UthmanicHafs'],
            fontSize: fontSize,
            height: 1.55,
            color: color,
            locale: const Locale('ar'),
          ),
        ),
      ),
    );
  }
}
