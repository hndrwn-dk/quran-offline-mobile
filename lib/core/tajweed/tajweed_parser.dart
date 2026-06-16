import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'tajweed_colors.dart';
import 'tajweed_html.dart';

/// Shared tajweed HTML → [TextSpan] parser for reader, juz, and mushaf.
class TajweedParser {
  TajweedParser._();

  static List<TextSpan> parseToSpans({
    required BuildContext context,
    required String tajweedHtml,
    required TextStyle baseStyle,
    Color? defaultColor,
    GestureRecognizer? recognizer,
    Color? backgroundColor,
    bool normalizeArabic = true,
  }) {
    final resolvedDefault = defaultColor ?? baseStyle.color ?? Colors.black;

    return _parse(
      tajweedHtml: tajweedHtml,
      baseStyle: baseStyle,
      colorForClass: (cls) => TajweedColors.colorForClass(
        cls,
        context,
        defaultColor: resolvedDefault,
      ),
      recognizer: recognizer,
      backgroundColor: backgroundColor,
      normalizeArabic: normalizeArabic,
    );
  }

  static List<TextSpan> parseToSpansWithColorFn({
    required String tajweedHtml,
    required TextStyle baseStyle,
    required Color Function(String tajweedClass) colorForClass,
    GestureRecognizer? recognizer,
    Color? backgroundColor,
    bool normalizeArabic = true,
  }) {
    return _parse(
      tajweedHtml: tajweedHtml,
      baseStyle: baseStyle,
      colorForClass: (cls) => colorForClass(TajweedColors.normalizeClass(cls)),
      recognizer: recognizer,
      backgroundColor: backgroundColor,
      normalizeArabic: normalizeArabic,
    );
  }

  static List<TextSpan> _parse({
    required String tajweedHtml,
    required TextStyle baseStyle,
    required Color Function(String tajweedClass) colorForClass,
    GestureRecognizer? recognizer,
    Color? backgroundColor,
    required bool normalizeArabic,
  }) {
    var text = tajweedHtml;
    if (normalizeArabic) {
      text = TajweedHtml.normalizeArabicForDisplay(text);
    }
    text = TajweedHtml.prepareForParsing(text);

    final spans = <TextSpan>[];
    final plainStyle = baseStyle.copyWith(backgroundColor: backgroundColor);
    final taggedStyle = (Color color) =>
        baseStyle.copyWith(color: color, backgroundColor: backgroundColor);

    TextSpan plainSpan(String content) => TextSpan(
          text: content,
          style: plainStyle,
          recognizer: recognizer,
        );

    TextSpan coloredSpan(String content, Color color) => TextSpan(
          text: content,
          style: taggedStyle(color),
          recognizer: recognizer,
        );

    final tajweedPatterns = [
      RegExp(r'<tajweed\s+class="([^"]+)"\s*>(.*?)</tajweed>',
          dotAll: true, caseSensitive: false),
      RegExp(r"<tajweed\s+class='([^']+)'\s*>(.*?)</tajweed>",
          dotAll: true, caseSensitive: false),
      RegExp(r'<tajweed\s+class=([^>\s]+)\s*>(.*?)</tajweed>',
          dotAll: true, caseSensitive: false),
      RegExp(r'<tajweed\s*>(.*?)</tajweed>', dotAll: true, caseSensitive: false),
    ];

    final spanPatterns = [
      RegExp(r'<span\s+class="([^"]+)"\s*>(.*?)</span>',
          dotAll: true, caseSensitive: false),
      RegExp(r"<span\s+class='([^']+)'\s*>(.*?)</span>",
          dotAll: true, caseSensitive: false),
      RegExp(r'<span\s+class=([^>\s]+)\s*>(.*?)</span>',
          dotAll: true, caseSensitive: false),
    ];

    final classPatterns = [
      RegExp(r'<class="([^"]+)"\s*>(.*?)</class>',
          dotAll: true, caseSensitive: false),
      RegExp(r"<class='([^']+)'\s*>(.*?)</class>",
          dotAll: true, caseSensitive: false),
      RegExp(r'<class=([^>\s]+)\s*>(.*?)</class>',
          dotAll: true, caseSensitive: false),
    ];

    final htmlTagPattern = RegExp(r'<[^>]+>');
    final allMatches = <_ParseMatch>[];

    bool isAlreadyMatched(int start, int end) =>
        allMatches.any((m) => m.start == start && m.end == end);

    void addTajweedMatches(RegExp pattern, {bool hasClass = true}) {
      for (final match in pattern.allMatches(text)) {
        if (isAlreadyMatched(match.start, match.end)) continue;
        allMatches.add(_ParseMatch(
          start: match.start,
          end: match.end,
          type: _ParseMatchType.tajweed,
          classAttr: hasClass ? (match.group(1) ?? '') : '',
          content: hasClass ? (match.group(2) ?? '') : (match.group(1) ?? ''),
        ));
      }
    }

    for (final p in tajweedPatterns) {
      addTajweedMatches(p, hasClass: p.pattern.contains('class'));
    }

    for (final p in classPatterns) {
      addTajweedMatches(p);
    }

    for (final pattern in spanPatterns) {
      for (final match in pattern.allMatches(text)) {
        if (isAlreadyMatched(match.start, match.end)) continue;
        allMatches.add(_ParseMatch(
          start: match.start,
          end: match.end,
          type: _ParseMatchType.span,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }

    allMatches.sort((a, b) => a.start.compareTo(b.start));

    String cleanPlain(String raw) {
      var s = raw;
      s = s.replaceAll(htmlTagPattern, '');
      s = s.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      s = s.replaceAll(RegExp(r'<tajweed[^>]*', caseSensitive: false), '');
      s = s.replaceAll(RegExp(r'<class=[^>]*', caseSensitive: false), '');
      return s;
    }

    var lastIndex = 0;
    for (final match in allMatches) {
      if (match.start > lastIndex) {
        final beforeText = cleanPlain(text.substring(lastIndex, match.start));
        if (beforeText.isNotEmpty) spans.add(plainSpan(beforeText));
      }

      if (match.type == _ParseMatchType.tajweed) {
        var content = cleanPlain(match.content);
        if (content.isNotEmpty) {
          spans.add(coloredSpan(content, colorForClass(match.classAttr)));
        }
      } else if (match.type == _ParseMatchType.span) {
        final classAttr = match.classAttr.trim();
        final isEndMarker = classAttr == 'end' ||
            classAttr == '"end"' ||
            classAttr == "'end'";
        if (!isEndMarker) {
          final content = cleanPlain(match.content);
          if (content.isNotEmpty) spans.add(plainSpan(content));
        }
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = cleanPlain(text.substring(lastIndex));
      if (remaining.isNotEmpty) spans.add(plainSpan(remaining));
    }

    if (spans.isEmpty) {
      return [plainSpan(cleanPlain(text))];
    }

    return spans;
  }
}

enum _ParseMatchType { tajweed, span }

class _ParseMatch {
  final int start;
  final int end;
  final _ParseMatchType type;
  final String classAttr;
  final String content;

  _ParseMatch({
    required this.start,
    required this.end,
    required this.type,
    required this.classAttr,
    required this.content,
  });
}
