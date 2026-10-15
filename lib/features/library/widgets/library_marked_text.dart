import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/inline_ayah_number.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';
import 'package:quran_offline/features/library/library_search.dart';

/// Small reference line under a Koleksi row.
TextStyle libraryMetaStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
      ) ??
      TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      );
}

class LibraryArabicLine extends StatelessWidget {
  const LibraryArabicLine({
    super.key,
    required this.arabic,
    this.query = '',
    this.verseHighlight,
    this.maxLines = 3,
    this.fontSize = 22,
    this.ayahNo,
  });

  final String arabic;
  final String query;
  final Color? verseHighlight;
  final int maxLines;
  final double fontSize;
  final int? ayahNo;

  @override
  Widget build(BuildContext context) {
    if (arabic.isEmpty && ayahNo == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final style = QuranArabicText.arabicDisplayStyle(
      fontSize: fontSize,
      color: colorScheme.onSurface,
      height: 1.7,
    );
    final ranges = query.trim().isEmpty
        ? const <LibraryMatchRange>[]
        : librarySnippetRanges(arabic, query);
    final marker = _ayahMarker(colorScheme);

    Widget text;
    if (ranges.isEmpty && marker == null) {
      text = QuranArabicText(
        arabic: arabic,
        fontSize: fontSize,
        defaultColor: colorScheme.onSurface,
        height: 1.7,
        textAlign: TextAlign.right,
        selectable: false,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      final body = ranges.isEmpty
          ? TextSpan(text: arabic, style: style)
          : _markedSpan(
              text: arabic,
              ranges: ranges,
              style: style,
              mark: style.copyWith(
                backgroundColor: colorScheme.primaryContainer,
              ),
            );
      text = Text.rich(
        marker == null
            ? body
            : TextSpan(style: style, children: [body, marker]),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (verseHighlight == null) return text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: verseHighlight!.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: text,
      ),
    );
  }

  WidgetSpan? _ayahMarker(ColorScheme colorScheme) {
    final number = ayahNo;
    if (number == null) return null;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InlineAyahNumber(
          ayahNo: number,
          fontSize: fontSize * 0.72,
          colorScheme: colorScheme,
          markerColor: colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class LibraryMarkedText extends StatelessWidget {
  const LibraryMarkedText({
    super.key,
    required this.text,
    required this.style,
    this.query = '',
    this.maxLines = 3,
  });

  final String text;
  final TextStyle style;
  final String query;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final ranges = query.trim().isEmpty ? const <LibraryMatchRange>[] : librarySnippetRanges(text, query);
    final mark = style.copyWith(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      ranges.isEmpty
          ? TextSpan(text: text, style: style)
          : _markedSpan(text: text, ranges: ranges, style: style, mark: mark),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

TextSpan _markedSpan({
  required String text,
  required List<LibraryMatchRange> ranges,
  required TextStyle style,
  required TextStyle mark,
}) {
  final children = <TextSpan>[];
  var cursor = 0;
  for (final range in ranges) {
    final start = range.start.clamp(0, text.length);
    final end = range.end.clamp(start, text.length);
    if (start > cursor) {
      children.add(TextSpan(text: text.substring(cursor, start), style: style));
    }
    if (end > start) {
      children.add(TextSpan(text: text.substring(start, end), style: mark));
    }
    cursor = end;
  }
  if (cursor < text.length) {
    children.add(TextSpan(text: text.substring(cursor), style: style));
  }
  return TextSpan(children: children, style: style);
}
