import 'package:flutter/material.dart';

/// Widget to render tajweed text with color coding
/// Parses HTML tajweed tags and applies appropriate colors
///
/// BACKUP: Pre-1.0.0+7 version (before Arabic diacritic merge fix).
/// To revert the tajweed rendering fix: copy this file over lib/core/widgets/tajweed_text.dart
class TajweedText extends StatelessWidget {
  final String tajweedHtml;
  final double fontSize;
  final Color defaultColor;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final double height;

  const TajweedText({
    super.key,
    required this.tajweedHtml,
    required this.fontSize,
    this.defaultColor = Colors.black,
    this.textDirection = TextDirection.rtl,
    this.textAlign = TextAlign.right,
    this.height = 1.7,
  });

  /// Get color for tajweed class
  Color getTajweedColor(String tajweedClass, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tajweed color mapping based on standard tajweed rules
    return switch (tajweedClass) {
      // Ikhfa (concealment) - Teal/Green
      'ikhfa' => isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00897B),
      // Idgham (merging) - Blue
      'idgham' => isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
      // Iqlab (conversion) - Purple
      'iqlab' => isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2),
      // Ghunnah (nasalization) - Orange
      'ghunnah' => isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
      // Qalqalah (echo) - Red
      'qalqalah' => isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
      // Ham wasl (connecting hamza) - Gray
      'ham_wasl' => colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      // Laam shamsiyah (solar lam) - Yellow
      'laam_shamsiyah' => isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17),
      // Madd (elongation)
      'madda_normal' => isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      'madda_permissible' => isDark ? const Color(0xFFA5D6A7) : const Color(0xFF388E3C),
      'madda_necessary' => isDark ? const Color(0xFF66BB6A) : const Color(0xFF1B5E20),
      'madda_obligatory' => isDark ? const Color(0xFF4CAF50) : const Color(0xFF0D47A1),
      // Silent letters - Light gray
      'silent' => colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      // Default - use default color
      _ => defaultColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final spans = _parseTajweedHtml(context);

    return SelectableText.rich(
      TextSpan(children: spans),
      textDirection: textDirection,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'UthmanicHafsV22',
        fontFamilyFallback: const ['UthmanicHafs'],
        height: height,
        color: defaultColor,
      ),
    );
  }

  List<TextSpan> _parseTajweedHtml(BuildContext context) {
    final spans = <TextSpan>[];
    String text = tajweedHtml;

    // Pattern to match tajweed tags: <tajweed class=class_name>content</tajweed>
    // Handle both quoted and unquoted class attributes
    // Pattern 1: <tajweed class="value">content</tajweed>
    // Pattern 2: <tajweed class='value'>content</tajweed>
    // Pattern 3: <tajweed class=value>content</tajweed>
    // Pattern 4: <tajweed>content</tajweed> (without class attribute)
    final tajweedPattern1 = RegExp(
      r'<tajweed\s+class="([^"]+)"\s*>(.*?)</tajweed>',
      dotAll: true,
      caseSensitive: false,
    );
    final tajweedPattern2 = RegExp(
      r"<tajweed\s+class='([^']+)'\s*>(.*?)</tajweed>",
      dotAll: true,
      caseSensitive: false,
    );
    final tajweedPattern3 = RegExp(
      r'<tajweed\s+class=([^>\s]+)\s*>(.*?)</tajweed>',
      dotAll: true,
      caseSensitive: false,
    );
    final tajweedPattern4 = RegExp(
      r'<tajweed\s*>(.*?)</tajweed>',
      dotAll: true,
      caseSensitive: false,
    );

    // Pattern for span tags: <span class=end>ayah_number</span>
    final spanPattern1 = RegExp(
      r'<span\s+class="([^"]+)"\s*>(.*?)</span>',
      dotAll: true,
      caseSensitive: false,
    );
    final spanPattern2 = RegExp(
      r"<span\s+class='([^']+)'\s*>(.*?)</span>",
      dotAll: true,
      caseSensitive: false,
    );
    final spanPattern3 = RegExp(
      r'<span\s+class=([^>\s]+)\s*>(.*?)</span>',
      dotAll: true,
      caseSensitive: false,
    );

    // Pattern for alternative format: <class=value>content</class>
    final classPattern1 = RegExp(
      r'<class="([^"]+)"\s*>(.*?)</class>',
      dotAll: true,
      caseSensitive: false,
    );
    final classPattern2 = RegExp(
      r"<class='([^']+)'\s*>(.*?)</class>",
      dotAll: true,
      caseSensitive: false,
    );
    final classPattern3 = RegExp(
      r'<class=([^>\s]+)\s*>(.*?)</class>',
      dotAll: true,
      caseSensitive: false,
    );

    // Pattern to remove any remaining HTML tags that weren't matched
    final htmlTagPattern = RegExp(r'<[^>]+>');

    int lastIndex = 0;

    // Find all matches
    final allMatches = <_Match>[];

    // Helper function to check if a match is already in allMatches
    bool isAlreadyMatched(int start, int end) {
      return allMatches.any((m) => m.start == start && m.end == end);
    }

    // Find tajweed tags (try all four patterns)
    for (final match in tajweedPattern1.allMatches(text)) {
      allMatches.add(_Match(
        start: match.start,
        end: match.end,
        type: _MatchType.tajweed,
        classAttr: match.group(1) ?? '',
        content: match.group(2) ?? '',
      ));
    }
    for (final match in tajweedPattern2.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.tajweed,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }
    for (final match in tajweedPattern3.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.tajweed,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }
    for (final match in tajweedPattern4.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.tajweed,
          classAttr: '',
          content: match.group(1) ?? '',
        ));
      }
    }

    // Find span tags (try all three patterns)
    for (final match in spanPattern1.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.span,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }
    for (final match in spanPattern2.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.span,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }
    for (final match in spanPattern3.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.span,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }

    // Find class tags (alternative format: <class=value>content</class>)
    for (final match in classPattern1.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.tajweed,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }
    for (final match in classPattern2.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.tajweed,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }
    for (final match in classPattern3.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_Match(
          start: match.start,
          end: match.end,
          type: _MatchType.tajweed,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
        ));
      }
    }

    // Sort matches by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Build text spans
    for (final match in allMatches) {
      // Add text before match (remove any HTML tags from it)
      if (match.start > lastIndex) {
        var beforeText = text.substring(lastIndex, match.start);
        beforeText = beforeText.replaceAll(htmlTagPattern, '');
        beforeText = beforeText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
        beforeText = beforeText.replaceAll(RegExp(r'<tajweed[^>]*', caseSensitive: false), '');
        beforeText = beforeText.replaceAll(RegExp(r'<class=[^>]*', caseSensitive: false), '');
        if (beforeText.isNotEmpty) {
          spans.add(TextSpan(text: beforeText));
        }
      }

      // Add styled text for match
      if (match.type == _MatchType.tajweed) {
        final tajweedClass = match.classAttr.trim();
        var content = match.content;
        content = content.replaceAll(htmlTagPattern, '');
        content = content.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');

        if (content.isNotEmpty) {
          final color = getTajweedColor(tajweedClass, context);
          spans.add(TextSpan(
            text: content,
            style: TextStyle(color: color),
          ));
        }
      } else if (match.type == _MatchType.span) {
        final classAttr = match.classAttr.trim();
        if (classAttr == 'end' || classAttr == '"end"' || classAttr == "'end'") {
          // Skip ayah number marker
        } else {
          var content = match.content;
          content = content.replaceAll(htmlTagPattern, '');
          if (content.isNotEmpty) {
            spans.add(TextSpan(text: content));
          }
        }
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      var remainingText = text.substring(lastIndex);
      remainingText = remainingText.replaceAll(htmlTagPattern, '');
      remainingText = remainingText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      remainingText = remainingText.replaceAll(RegExp(r'<tajweed[^>]*', caseSensitive: false), '');
      remainingText = remainingText.replaceAll(RegExp(r'<class=[^>]*', caseSensitive: false), '');
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText));
      }
    }

    // If no matches found, remove all HTML tags and return plain text
    if (spans.isEmpty) {
      var cleanedText = text.replaceAll(htmlTagPattern, '');
      cleanedText = cleanedText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      cleanedText = cleanedText.replaceAll(RegExp(r'<tajweed[^>]*', caseSensitive: false), '');
      cleanedText = cleanedText.replaceAll(RegExp(r'<class=[^>]*', caseSensitive: false), '');
      return [TextSpan(text: cleanedText)];
    }

    return spans;
  }
}

enum _MatchType {
  tajweed,
  span,
}

class _Match {
  final int start;
  final int end;
  final _MatchType type;
  final String classAttr;
  final String content;

  _Match({
    required this.start,
    required this.end,
    required this.type,
    required this.classAttr,
    required this.content,
  });
}
