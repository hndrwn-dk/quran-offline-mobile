import 'package:flutter/material.dart';

/// Widget to render tajweed text with color coding
/// Parses HTML tajweed tags and applies appropriate colors
///
/// To avoid Flutter's Arabic diacritic rendering issue (diacritics mis-positioned
/// when split across TextSpans), we merge any leading combining characters
/// from each span into the previous span so no span starts with a diacritic.
class TajweedText extends StatelessWidget {
  final String tajweedHtml;
  final double fontSize;
  final Color defaultColor;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final double height;
  
  /// Optional: If true, replace problematic Arabic characters with regular alif as fallback.
  final bool replaceWaslaWithAlif;

  /// When true (light theme), use UthmanicHafsV22 as primary font so lam/lam-alif render correctly on light background.
  final bool isLightTheme;

  const TajweedText({
    super.key,
    required this.tajweedHtml,
    required this.fontSize,
    this.defaultColor = Colors.black,
    this.textDirection = TextDirection.rtl,
    this.textAlign = TextAlign.right,
    this.height = 1.7,
    this.replaceWaslaWithAlif = false,
    this.isLightTheme = false,
  });
  
  /// Normalizes Arabic text for display only (font rendering). See docs/QURAN_TEXT_INTEGRITY.md:
  /// principle: Al-Quran — jangan menambahkan atau menghilangkan.
  /// - Unify equivalent forms only: U+06DF → U+06E0 so أَنَا۠ displays consistently (no removal).
  /// - Replace/remove only for display when font has no glyph (tofu) or char is redundant with UI.
  static String normalizeArabicForDisplay(String arabic) {
    return arabic
        .replaceAll('\u0671', '\u0627') // Alef Wasla
        .replaceAll('\u0672', '\u0627') // Alef with Wavy Hamza Below (maddla)
        .replaceAll('\u065F', '') // Arabic Wavy Hamza Below - renders as circle, no glyph in font
        .replaceAll('\u0670', '') // ARABIC LETTER SUPERSCRIPT ALEF - renders as circle
        .replaceAll('\u06A0', '') // Arabic letter that can render as circle in some fonts
        .replaceAll('\u06DD', '') // ARABIC END OF AYAH - ayah number shown separately in UI
        .replaceAll('\u06D9', '') // ARABIC SMALL HIGH LAM ALEF (waqf) - often renders as circle
        .replaceAll('\u06DA', '') // ARABIC SMALL HIGH JEEM - often renders as circle
        .replaceAll('\u06DF', '\u06E0'); // Unify small high rounded → U+06E0 so أَنَا۠ displays (kept, not removed)
  }

  /// Strips all HTML tags from tajweed string and normalizes for display.
  /// Use this when tajweed is OFF so we show the same character stream as when
  /// tajweed is ON (from JSON "tj"), just without colors — avoids circles from
  /// font missing glyphs and keeps one source of truth.
  static String plainArabicFromTajweedHtml(String tajweedHtml) {
    final stripped = tajweedHtml.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&nbsp;', ' ').trim();
    return normalizeArabicForDisplay(stripped);
  }

  /// TextStyle for plain Arabic (no tajweed) so rendering matches and avoids tofu.
  /// Use with [normalizeArabicForDisplay] when showing verse.arabic with tajweed off.
  /// Uses UthmanicHafsV22 as primary so lam/lam-alif render correctly in both light and dark theme.
  static TextStyle arabicDisplayStyle({
    required double fontSize,
    required Color color,
    double height = 1.7,
    bool isLightTheme = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: 'UthmanicHafsV22',
      fontFamilyFallback: const ['UthmanicHafs', 'KFGQPCUthmanic', 'ScheherazadeNew'],
      height: height,
      color: color,
      locale: const Locale('ar'),
    );
  }

  /// Creates a consistent TextStyle for Quran Arabic text with proper font family and locale.
  /// Uses UthmanicHafsV22 so lam/lam-alif render correctly in both light and dark theme.
  TextStyle quranArabicStyle({
    double? fontSize,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: 'UthmanicHafsV22',
      fontFamilyFallback: const ['UthmanicHafs', 'KFGQPCUthmanic', 'ScheherazadeNew'],
      height: height ?? this.height,
      color: color ?? defaultColor,
      locale: const Locale('ar'),
    );
  }

  /// Get color for tajweed class
  Color getTajweedColor(String tajweedClass, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Tajweed color mapping based on standard tajweed rules
    return switch (tajweedClass) {
      // Ikhfa (concealment) - Teal/Green
      'ikhfa' => isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00897B),
      'ikhafa_shafawi' => isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00897B), // Ikhfa with shafawi - same as ikhfa
      // Idgham (merging) - Blue
      'idgham' => isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
      'idgham_ghunnah' => defaultColor, // Idgham with ghunnah - Default (white/black) - treated as regular text like mad asli/harakat
      'idgham_shafawi' => isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2), // Idgham with shafawi - Blue (idgham color)
      'idgham_wo_ghunnah' => isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2), // Idgham without ghunnah - Blue (idgham color)
      // Iqlab (conversion) - Purple
      'iqlab' => isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2),
      // Ghunnah (nasalization) - Orange
      'ghunnah' => isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
      // Qalqalah (echo) - Red
      'qalqalah' => isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
      'qalaqah' => isDark ? const Color(0xFFE57373) : const Color(0xFFC62828), // Alternative spelling - same as qalqalah
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
      'slnt' => colorScheme.onSurfaceVariant.withValues(alpha: 0.4), // Abbreviated form
      // Default - use default color (white/black based on theme)
      _ => defaultColor,
    };
  }

  /// Returns true if [codePoint] is an Arabic combining mark (harakah, madda, etc.)
  /// that must stay with the previous base character for correct layout.
  static bool _isArabicCombining(int codePoint) {
    // Arabic tatweel (kashida) - often part of madda sequence like ـٰ
    if (codePoint == 0x0640) return true;
    // Arabic combining marks: Fathatan, Dammatan, Kasratan, Fatha, Damma, Kasra, Shadda, Sukun (U+064B–U+0652)
    if (codePoint >= 0x064B && codePoint <= 0x0652) return true;
    // Arabic madda, hamza above, hamza below (U+0653–U+0655)
    if (codePoint >= 0x0653 && codePoint <= 0x0655) return true;
    // Arabic letter superscript alif (used in madda)
    if (codePoint == 0x0670) return true;
    // Note: U+0671 (Alef Wasla) and U+0672 (Alef with Wavy Hamza Below) are base characters,
    // not combining marks, so they don't need to be merged with previous spans.
    // However, they may not be supported by all fonts and may render as black circles.
    return false;
  }

  /// Returns the leading substring of [s] that consists only of Arabic combining characters.
  static String _leadingCombining(String s) {
    if (s.isEmpty) return '';
    final runes = s.runes.toList();
    int i = 0;
    while (i < runes.length && _isArabicCombining(runes[i])) {
      i++;
    }
    if (i == 0) return '';
    return String.fromCharCodes(runes.sublist(0, i));
  }

  /// Merges leading combining characters from each span into the previous span
  /// so that Flutter never lays out a diacritic in a separate span (fixes overlap/missing harakat).
  /// 
  /// IMPORTANT: Preserves the style from the previous span to ensure font consistency.
  /// If the previous span has no style, we ensure the merged span gets proper font styling.
  List<TextSpan> _mergeLeadingCombiningIntoPrevious(List<TextSpan> spans) {
    if (spans.length <= 1) return spans;
    final result = <TextSpan>[];
    for (int i = 0; i < spans.length; i++) {
      final span = spans[i];
      final text = span.text ?? '';
      if (text.isEmpty) continue;
      final leading = _leadingCombining(text);
      if (leading.isNotEmpty && result.isNotEmpty) {
        // Prepend leading diacritics to the last span so they stay with the previous base character
        final last = result.removeLast();
        final newLastText = (last.text ?? '') + leading;
        // Preserve the style from the previous span, or use default if none exists
        final preservedStyle = last.style ?? quranArabicStyle();
        result.add(TextSpan(
          text: newLastText,
          style: preservedStyle,
        ));
        final rest = text.substring(leading.length);
        if (rest.isNotEmpty) {
          // Preserve the style from the current span, or use default if none exists
          final restStyle = span.style ?? quranArabicStyle();
          result.add(TextSpan(text: rest, style: restStyle));
        }
      } else {
        result.add(span);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Apply wasla/maddla fallback if enabled
    String processedHtml = tajweedHtml;
    if (replaceWaslaWithAlif) {
      processedHtml = processedHtml.replaceAll('\u0671', '\u0627').replaceAll('\u0672', '\u0627');
    }
    // Normalize so U+065F, U+06A0 etc. don't render as circle (e.g. 6:56, 6:44)
    processedHtml = normalizeArabicForDisplay(processedHtml);

    List<TextSpan> spans = _parseTajweedHtml(context, processedHtml);
    spans = _mergeLeadingCombiningIntoPrevious(spans);

    // Wrap with Localizations.override to set Arabic locale for proper text shaping
    return Localizations.override(
      context: context,
      locale: const Locale('ar'),
      child: SelectableText.rich(
        TextSpan(children: spans),
        textDirection: textDirection,
        textAlign: textAlign,
        style: quranArabicStyle(),
      ),
    );
  }

  List<TextSpan> _parseTajweedHtml(BuildContext context, [String? htmlText]) {
    final spans = <TextSpan>[];
    String text = htmlText ?? tajweedHtml;
    
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
          classAttr: '', // No class attribute
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
        // Remove any HTML tags that weren't matched
        // Also remove incomplete tags like <tajweed, <class=, etc.
        beforeText = beforeText.replaceAll(htmlTagPattern, '');
        // Remove incomplete tags that don't have closing >
        beforeText = beforeText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
        beforeText = beforeText.replaceAll(RegExp(r'<tajweed[^>]*', caseSensitive: false), '');
        beforeText = beforeText.replaceAll(RegExp(r'<class=[^>]*', caseSensitive: false), '');
        if (beforeText.isNotEmpty) {
          spans.add(TextSpan(
            text: beforeText,
            style: quranArabicStyle(),
          ));
        }
      }
      
      // Add styled text for match
      if (match.type == _MatchType.tajweed) {
        final tajweedClass = match.classAttr.trim();
        // Clean content from any remaining HTML tags
        var content = match.content;
        content = content.replaceAll(htmlTagPattern, '');
        content = content.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
        
        if (content.isNotEmpty) {
          // Some tajweed classes should be rendered as plain text (no color)
          // because they're just regular harakat/diacritics (mad asli, waṣlah, silent), not actual tajweed rules
          // These should appear as white/default text, not colored circles or black circles
          final classesToRenderAsPlainText = {
            'idgham_ghunnah', // Just harakat/diacritics, not a tajweed rule - should be white/default
            'madda_normal', // Mad asli (natural elongation) - regular harakat, should be white/default, not green/black circle
            'madda_obligatory', // Madd wajib - regular harakat, should be white/default, not black circle
            'madda_permissible', // Madd jaiz - regular harakat, should be white/default
            'madda_necessary', // Madd lazim - regular harakat, should be white/default
            'ham_wasl', // Waṣlah (connecting hamza) - regular harakat sign, should be white/default, not black circle
            'slnt', // Silent letters - regular harakat, should be white/default, not black circle
            'silent', // Silent letters (alternative) - regular harakat, should be white/default, not black circle
          };
          
          if (classesToRenderAsPlainText.contains(tajweedClass)) {
            // Render as plain text (default color) - these are just harakat/mad asli/waṣlah/silent, not tajweed rules
            // No colored circle (green/black) should appear - just regular text with default color
            spans.add(TextSpan(
              text: content,
              style: quranArabicStyle(),
            ));
          } else {
            final color = getTajweedColor(tajweedClass, context);
            spans.add(TextSpan(
              text: content,
              style: quranArabicStyle(color: color),
            ));
          }
        }
      } else if (match.type == _MatchType.span) {
        // Check if this is the end marker: <span class=end>...</span>
        final classAttr = match.classAttr.trim();
        // Match exactly "end" (with or without quotes)
        if (classAttr == 'end' || classAttr == '"end"' || classAttr == "'end'") {
          // Skip ayah number marker - we already display it as a badge
          // Do nothing, just skip this match
        } else {
          // Regular span (not end marker) - render it
          var content = match.content;
          content = content.replaceAll(htmlTagPattern, '');
          if (content.isNotEmpty) {
            spans.add(TextSpan(
              text: content,
              style: quranArabicStyle(),
            ));
          }
        }
      }
      
      lastIndex = match.end;
    }
    
    // Add remaining text (remove any HTML tags from it)
    if (lastIndex < text.length) {
      var remainingText = text.substring(lastIndex);
      // Remove any HTML tags that weren't matched
      remainingText = remainingText.replaceAll(htmlTagPattern, '');
      // Remove incomplete tags
      remainingText = remainingText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      remainingText = remainingText.replaceAll(RegExp(r'<tajweed[^>]*', caseSensitive: false), '');
      remainingText = remainingText.replaceAll(RegExp(r'<class=[^>]*', caseSensitive: false), '');
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: quranArabicStyle(),
        ));
      }
    }
    
    // If no matches found, remove all HTML tags and return plain text
    if (spans.isEmpty) {
      var cleanedText = text.replaceAll(htmlTagPattern, '');
      cleanedText = cleanedText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      cleanedText = cleanedText.replaceAll(RegExp(r'<tajweed[^>]*', caseSensitive: false), '');
      cleanedText = cleanedText.replaceAll(RegExp(r'<class=[^>]*', caseSensitive: false), '');
      return [TextSpan(
        text: cleanedText,
        style: quranArabicStyle(),
      )];
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

