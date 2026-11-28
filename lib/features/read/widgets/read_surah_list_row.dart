import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/read/widgets/read_surah_badge.dart';

/// Shared surah row for Baca lists (Surah / Juz / Mushaf).
class ReadSurahListRow extends StatelessWidget {
  const ReadSurahListRow({
    super.key,
    required this.surahId,
    required this.name,
    this.meaning,
    this.trailingDetail,
    this.showGlyph = true,
  });

  final int surahId;
  final String name;
  final String? meaning;
  final String? trailingDetail;
  final bool showGlyph;

  /// Row padding inside a grouped card (min row height 56).
  static const EdgeInsets padding = EdgeInsets.fromLTRB(16, 10, 16, 10);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasMeaning = meaning != null && meaning!.isNotEmpty;
    final hasDetail = trailingDetail != null && trailingDetail!.isNotEmpty;
    final detailStyle = textTheme.bodySmall?.copyWith(
      fontSize: 13,
      color: colorScheme.onSurfaceVariant,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          ReadSurahBadge(surahId: surahId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (hasMeaning || hasDetail) ...[
                  const SizedBox(height: 2),
                  _SurahRowDetail(
                    meaning: hasMeaning ? meaning! : null,
                    detail: hasDetail ? trailingDetail! : null,
                    style: detailStyle,
                  ),
                ],
              ],
            ),
          ),
          if (showGlyph) ...[
            const SizedBox(width: 12),
            // Real glyphs are about 40-75dp wide at this size, so the cap never
            // scales them; it only stops a fallback font overflowing the row.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: SurahNameListGlyph(
                  surahId: surahId,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Meaning · 7 verses" on one line when it fits; otherwise the verse count
/// moves to its own line so it never breaks mid-phrase.
class _SurahRowDetail extends StatelessWidget {
  const _SurahRowDetail({this.meaning, this.detail, this.style});

  final String? meaning;
  final String? detail;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final meaning = this.meaning;
    final detail = this.detail;
    if (meaning == null || detail == null) {
      return Text(meaning ?? detail ?? '', style: style);
    }
    final joined = '$meaning · $detail';

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: joined, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final fits = painter.width <= constraints.maxWidth;
        painter.dispose();
        if (fits) return Text(joined, style: style);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(meaning, style: style),
            Text(detail, style: style),
          ],
        );
      },
    );
  }
}
