import 'package:flutter/material.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';
import 'package:quran_offline/core/tajweed/tajweed_parser.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

/// Dev spike: compare tanwin/idgham rendering (Ali 'Imran 3:3) across fonts.
class FontCompareScreen extends StatelessWidget {
  const FontCompareScreen({super.key});

  /// From assets/quran/s003.json ayah 3 — `tj` field.
  static const _verse3Tj =
      'نَزَّلَ عَلَيْكَ <tajweed class=ham_wasl>ٱ</tajweed>لْكِتَ<tajweed class=madda_normal>ـٰ</tajweed>بَ بِ<tajweed class=ham_wasl>ٱ</tajweed>لْحَقِّ مُصَدِّ<tajweed class=idgham_wo_ghunnah>قًا ل</tajweed>ِّمَا بَيْنَ يَدَيْهِ وَأَ<tajweed class=ikhafa>نز</tajweed>َلَ <tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed>تَّوْرَ<tajweed class=madda_normal>ٮٰ</tajweed>ةَ وَ<tajweed class=ham_wasl>ٱ</tajweed>لْإِ<tajweed class=ikhafa>نج</tajweed><tajweed class=madda_permissible>ِي</tajweed>لَ';

  static const _focusSnippetTj =
      'مُصَدِّ<tajweed class=idgham_wo_ghunnah>قًا ل</tajweed>ِّمَا';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font compare — 3:3'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Perbandingan tanwin pada ق dalam مُصَدِّقًا (idgham tanpa ghunnah). '
            'Quran.com sering menampilkan dua fathah tidak sejajar; periksa apakah font lain lebih dekat.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          _QulFontNote(colorScheme: colorScheme, textTheme: textTheme),
          const SizedBox(height: 8),
          Text(
            'Unicode: ق U+0642 + ً U+064B (fathatan standar) + ا U+0627',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'CUPLIKAN (diperbesar)',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in QuranFonts.compareCandidates.entries)
            _FontSampleCard(
              fontFamily: entry.key,
              label: entry.value,
              tajweedHtml: _focusSnippetTj,
              fontSize: 36,
              emphasized: true,
            ),
          const SizedBox(height: 24),
          Text(
            'AYAT PENUH 3:3',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in QuranFonts.compareCandidates.entries)
            _FontSampleCard(
              fontFamily: entry.key,
              label: entry.value,
              tajweedHtml: _verse3Tj,
              fontSize: 22,
            ),
        ],
      ),
    );
  }
}

class _QulFontNote extends StatelessWidget {
  const _QulFontNote({
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan QUL (qul.tarteel.ai)',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'QPC V2 (#249) memakai 604 font ligatur per halaman Mushaf Madinah — '
              'bukan Unicode ayat, jadi tidak bisa dipakai di reader tajweed ini.\n'
              'Untuk Unicode Madinah 1421H, QUL menawarkan Digital Khatt V2 (#247) '
              '(ditambahkan di bawah). QPC Hafs (#245) sama dengan Uthmanic Hafs V22 '
              'yang sudah dipakai app.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSampleCard extends StatelessWidget {
  const _FontSampleCard({
    required this.fontFamily,
    required this.label,
    required this.tajweedHtml,
    required this.fontSize,
    this.emphasized = false,
  });

  final String fontFamily;
  final String label;
  final String tajweedHtml;
  final double fontSize;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 10),
            Localizations.override(
              context: context,
              locale: const Locale('ar'),
              child: _TajweedWithFont(
                tajweedHtml: tajweedHtml,
                fontFamily: fontFamily,
                fontSize: fontSize,
                color: colorScheme.onSurface,
                emphasized: emphasized,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TajweedWithFont extends StatelessWidget {
  const _TajweedWithFont({
    required this.tajweedHtml,
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    this.emphasized = false,
  });

  final String tajweedHtml;
  final String fontFamily;
  final double fontSize;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontFamilyFallback: const [
        QuranFonts.uthmanicHafsV22,
        QuranFonts.kfgqpcUthmanic,
        QuranFonts.digitalKhattV2,
      ],
      height: 1.8,
      color: color,
      locale: const Locale('ar'),
    );

    var spans = TajweedParser.parseToSpans(
      context: context,
      tajweedHtml: tajweedHtml,
      baseStyle: baseStyle,
      defaultColor: color,
    );
    spans = TajweedText.coalesceSpansForArabicLayout(
      spans,
      defaultStyle: baseStyle,
    );

    final text = SelectableText.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: baseStyle,
    );

    if (!emphasized) return text;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: text,
      ),
    );
  }
}
