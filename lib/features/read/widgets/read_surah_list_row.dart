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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadSurahBadge(surahId: surahId),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (meaning != null && meaning!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  meaning!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showGlyph || trailingDetail != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showGlyph) SurahNameListGlyph(surahId: surahId),
              if (trailingDetail != null) ...[
                if (showGlyph) const SizedBox(height: 4),
                Text(
                  trailingDetail!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
