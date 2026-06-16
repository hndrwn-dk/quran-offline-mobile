import 'package:flutter/material.dart';

import '../tajweed/tajweed_colors.dart';
import '../tajweed/tajweed_html.dart';
import '../tajweed/tajweed_parser.dart';

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
  static String normalizeArabicForDisplay(String arabic) =>
      TajweedHtml.normalizeArabicForDisplay(arabic);

  /// Strips all HTML tags from tajweed string and normalizes for display.
  /// Use this when tajweed is OFF so we show the same character stream as when
  /// tajweed is ON (from JSON "tj"), just without colors — avoids circles from
  /// font missing glyphs and keeps one source of truth.
  static String plainArabicFromTajweedHtml(String tajweedHtml) =>
      TajweedHtml.plainArabicFromHtml(tajweedHtml);

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

  /// Get color for tajweed class (Quran.com-aligned palette).
  Color getTajweedColor(String tajweedClass, BuildContext context) {
    return TajweedColors.colorForClass(
      tajweedClass,
      context,
      defaultColor: defaultColor,
    );
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
  /// Then merges spans split by tajweed tags inside the same Arabic word (e.g. أَصْحَ + ـٰ + بُ)
  /// so cursive letters like ب and ت are not clipped.
  static List<TextSpan> coalesceSpansForArabicLayout(
    List<TextSpan> spans, {
    TextStyle? defaultStyle,
  }) {
    final merged = mergeLeadingCombiningIntoPrevious(spans, defaultStyle: defaultStyle);
    return mergeSplitArabicWords(merged, defaultStyle: defaultStyle);
  }

  /// Returns true if [codePoint] is a base Arabic letter (not a combining mark).
  static bool isArabicLetter(int codePoint) {
    return (codePoint >= 0x0621 && codePoint <= 0x064A) ||
        codePoint == 0x0671 ||
        codePoint == 0x0672 ||
        codePoint == 0x06CC;
  }

  static int? _firstBaseLetterCodePoint(String s) {
    for (final cp in s.runes) {
      if (isArabicLetter(cp)) return cp;
    }
    return null;
  }

  static int? _lastBaseLetterCodePoint(String s) {
    final runes = s.runes.toList();
    for (var i = runes.length - 1; i >= 0; i--) {
      if (isArabicLetter(runes[i])) return runes[i];
    }
    return null;
  }

  /// True when [s] is a single letter plus optional diacritics (typical tajweed tag split).
  static bool _isShortArabicFragment(String s) {
    var letters = 0;
    for (final cp in s.runes) {
      if (isArabicLetter(cp)) letters++;
    }
    return letters == 1 && s.length <= 4;
  }

  /// Whether two adjacent span texts were split inside one Arabic word and must be one span.
  static bool shouldMergeArabicSpans(
    String prev,
    String curr, {
    Color? defaultColor,
    Color? prevColor,
    Color? currColor,
  }) {
    if (prev.isEmpty || curr.isEmpty) return false;

    final prevLast = prev.runes.last;
    final currFirst = curr.runes.first;

    if (prevLast == 0x20 || prevLast == 0xA0) return false;
    if (currFirst == 0x20 || currFirst == 0xA0) return false;

    // Madda bridge: أَصْحَ + ـٰ + بُ (always merge for glyph shaping)
    if (prevLast == 0x0640 || prevLast == 0x0670) return true;

    // Span is only combining marks (tatweel, harakat).
    if (curr.runes.every(_isArabicCombining)) return true;

    // Do not merge colored tajweed into plain letters (or vice versa).
    if (defaultColor != null) {
      final prevColored = prevColor != null && prevColor != defaultColor;
      final currColored = currColor != null && currColor != defaultColor;
      if (prevColored != currColored) return false;
    }

    if (_isArabicCombining(prevLast) && isArabicLetter(currFirst)) return true;

    final prevBase = _lastBaseLetterCodePoint(prev);
    final currBase = _firstBaseLetterCodePoint(curr);
    if (prevBase != null &&
        currBase != null &&
        isArabicLetter(prevBase) &&
        isArabicLetter(currBase) &&
        (_isShortArabicFragment(curr) || _isShortArabicFragment(prev))) {
      if (_colorsBlockMerge(prevColor, currColor, defaultColor)) return false;
      return true;
    }

    return false;
  }

  static bool _colorsBlockMerge(Color? a, Color? b, Color? defaultColor) {
    if (a == null || b == null || defaultColor == null) return false;
    final aColored = a != defaultColor;
    final bColored = b != defaultColor;
    return aColored && bColored && a != b;
  }

  /// Merges spans that tajweed HTML split inside one Arabic word (fixes clipped ب / ت / ل, etc.).
  static List<TextSpan> mergeSplitArabicWords(
    List<TextSpan> spans, {
    TextStyle? defaultStyle,
  }) {
    if (spans.length <= 1) return spans;

    final result = <TextSpan>[];
    for (final span in spans) {
      final text = span.text ?? '';
      if (text.isEmpty) continue;

      if (result.isEmpty) {
        result.add(span);
        continue;
      }

      final prev = result.last;
      final prevText = prev.text ?? '';
      final defaultColor = defaultStyle?.color;
      if (shouldMergeArabicSpans(
        prevText,
        text,
        defaultColor: defaultColor,
        prevColor: prev.style?.color,
        currColor: span.style?.color,
      )) {
        result.removeLast();
        result.add(TextSpan(
          text: prevText + text,
          style: _styleForMergedSpans(prev.style, span.style, defaultStyle),
          recognizer: prev.recognizer ?? span.recognizer,
        ));
      } else {
        result.add(span);
      }
    }
    return result;
  }

  static TextStyle? _styleForMergedSpans(
    TextStyle? a,
    TextStyle? b,
    TextStyle? defaultStyle,
  ) {
    final defaultColor = defaultStyle?.color;
    if (defaultColor != null) {
      // Keep tajweed hue when merging a colored tag with default text.
      if (a?.color != null && a!.color != defaultColor) return a;
      if (b?.color != null && b!.color != defaultColor) return b;
    }
    return a ?? b ?? defaultStyle;
  }

  /// Merges leading combining characters from each span into the previous span
  /// so that Flutter never lays out a diacritic in a separate span (fixes overlap/missing harakat).
  ///
  /// IMPORTANT: Preserves the style from the previous span to ensure font consistency.
  /// If the previous span has no style, we ensure the merged span gets proper font styling.
  static List<TextSpan> mergeLeadingCombiningIntoPrevious(
    List<TextSpan> spans, {
    TextStyle? defaultStyle,
  }) {
    if (spans.length <= 1) return spans;
    final result = <TextSpan>[];
    for (int i = 0; i < spans.length; i++) {
      final span = spans[i];
      final text = span.text ?? '';
      if (text.isEmpty) continue;
      final leading = _leadingCombining(text);
      if (leading.isNotEmpty && result.isNotEmpty) {
        final last = result.last;
        final rest = text.substring(leading.length);
        final lastColor = last.style?.color ?? defaultStyle?.color;
        final currColor = span.style?.color ?? defaultStyle?.color;
        final currAllCombining = text.runes.every(_isArabicCombining);

        if (!currAllCombining && lastColor != currColor) {
          result.add(span);
          continue;
        }

        // Prepend leading diacritics to the last span so they stay with the previous base character
        result.removeLast();
        final newLastText = (last.text ?? '') + leading;
        // Preserve the style from the previous span, or use default if none exists
        final preservedStyle = last.style ?? defaultStyle;
        result.add(TextSpan(
          text: newLastText,
          style: preservedStyle,
          recognizer: last.recognizer,
        ));
        if (rest.isNotEmpty) {
          final restStyle = span.style ?? defaultStyle;
          result.add(TextSpan(
            text: rest,
            style: restStyle,
            recognizer: span.recognizer,
          ));
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

    List<TextSpan> spans = TajweedParser.parseToSpans(
      context: context,
      tajweedHtml: processedHtml,
      baseStyle: quranArabicStyle(),
      defaultColor: defaultColor,
    );
    final baseStyle = quranArabicStyle();
    spans = coalesceSpansForArabicLayout(spans, defaultStyle: baseStyle);

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
}
