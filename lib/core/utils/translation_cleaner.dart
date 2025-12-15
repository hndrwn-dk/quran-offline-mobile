/// Utility class to clean translation text from HTML-like tags
class TranslationCleaner {
  /// Removes footnote tags like <sup foot_note=xxx>1</sup> from translation text
  static String clean(String? text) {
    if (text == null || text.isEmpty) return text ?? '';
    
    // Remove <sup foot_note=xxx>...</sup> tags
    // Pattern matches: <sup foot_note=any_number>any_content</sup>
    return text.replaceAll(
      RegExp(r'<sup\s+foot_note=\d+>.*?</sup>', caseSensitive: false),
      '',
    ).trim();
  }
}

