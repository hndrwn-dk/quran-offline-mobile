/// Utility class to clean translation text from HTML-like tags and numbering
class TranslationCleaner {
  /// Removes footnote tags and leading numbers from translation text
  static String clean(String? text) {
    if (text == null || text.isEmpty) return text ?? '';
    
    // Remove <sup foot_note=xxx>...</sup> tags
    // Pattern matches: <sup foot_note=any_number>any_content</sup>
    String cleaned = text.replaceAll(
      RegExp(r'<sup\s+foot_note=\d+>.*?</sup>', caseSensitive: false),
      '',
    );
    
    // Remove leading numbers with period and space at the start of the string
    // Pattern: one or more digits followed by period and one or more whitespace characters
    // This handles: "1. ", "2. ", "123. Text", etc.
    // First, try to match with space after period
    final leadingNumberPattern = RegExp(r'^(\d+)\.\s+(.*)$');
    final match = leadingNumberPattern.firstMatch(cleaned);
    if (match != null) {
      // Extract the text after the number and period
      cleaned = match.group(2) ?? cleaned;
    } else {
      // Fallback: try without space requirement
      cleaned = cleaned.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    }
    
    return cleaned.trim();
  }
}

