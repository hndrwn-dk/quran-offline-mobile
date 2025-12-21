import 'package:flutter/material.dart';

/// Widget to render tajweed text with color coding
/// Parses HTML tajweed tags and applies appropriate colors
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
    final text = tajweedHtml;
    
    // Pattern to match tajweed tags: <tajweed class=class_name>content</tajweed>
    // Also handle <span class=end>ayah_number</span> for ayah numbers
    final tajweedPattern = RegExp(
      r'<tajweed\s+class=([^>]+)>(.*?)</tajweed>',
      dotAll: true,
    );
    final spanPattern = RegExp(r'<span\s+class=([^>]+)>(.*?)</span>', dotAll: true);
    
    int lastIndex = 0;
    
    // Find all matches
    final allMatches = <_Match>[];
    
    // Find tajweed tags
    for (final match in tajweedPattern.allMatches(text)) {
      allMatches.add(_Match(
        start: match.start,
        end: match.end,
        type: _MatchType.tajweed,
        classAttr: match.group(1) ?? '',
        content: match.group(2) ?? '',
      ));
    }
    
    // Find span tags (for ayah numbers)
    for (final match in spanPattern.allMatches(text)) {
      allMatches.add(_Match(
        start: match.start,
        end: match.end,
        type: _MatchType.span,
        classAttr: match.group(1) ?? '',
        content: match.group(2) ?? '',
      ));
    }
    
    // Sort matches by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    // Build text spans
    for (final match in allMatches) {
      // Add text before match
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        if (beforeText.isNotEmpty) {
          spans.add(TextSpan(text: beforeText));
        }
      }
      
      // Add styled text for match
      if (match.type == _MatchType.tajweed) {
        final tajweedClass = match.classAttr.trim();
        final color = getTajweedColor(tajweedClass, context);
        spans.add(TextSpan(
          text: match.content,
          style: TextStyle(color: color),
        ));
      } else if (match.type == _MatchType.span) {
        // Check if this is the end marker: <span class=end>...</span>
        final classAttr = match.classAttr.trim();
        // Match exactly "end" (with or without quotes)
        if (classAttr == 'end' || classAttr == '"end"' || classAttr == "'end'") {
          // Skip ayah number marker - we already display it as a badge
          // Do nothing, just skip this match
        } else {
          // Regular span (not end marker) - render it
          spans.add(TextSpan(text: match.content));
        }
      } else {
        // Regular span
        spans.add(TextSpan(text: match.content));
      }
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText));
      }
    }
    
    // If no matches found, return plain text
    if (spans.isEmpty) {
      return [TextSpan(text: text)];
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

