/// Converts QUL tafsir HTML to plain readable text for Flutter widgets.
class TafsirHtml {
  TafsirHtml._();

  static final _entityPattern = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|\w+);');

  static String toPlainText(String? html) {
    if (html == null || html.trim().isEmpty) return '';

    var text = html;
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = _decodeEntities(text);
    text = text.replaceAll('\r', '');
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// Cleans line-break artifacts common in bundled QUL tafsir HTML.
  static String polishPlainText(String text) {
    if (text.isEmpty) return text;

    var polished = text;
    polished = polished.replaceAll(RegExp(r'-\s*\n\s*'), '');
    polished = polished.replaceAll('\r', '');
    polished = polished.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    polished = polished.replaceAll(RegExp(r'(?<!\n)\n(?!\n)'), ' ');
    polished = polished.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    polished = polished.replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1');
    polished = polished.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return polished.trim();
  }

  static String _decodeEntities(String input) {
    return input.replaceAllMapped(_entityPattern, (match) {
      final token = match.group(1)!;
      if (token.startsWith('#x')) {
        final code = int.tryParse(token.substring(2), radix: 16);
        return code != null ? String.fromCharCode(code) : match.group(0)!;
      }
      if (token.startsWith('#')) {
        final code = int.tryParse(token.substring(1));
        return code != null ? String.fromCharCode(code) : match.group(0)!;
      }
      return switch (token) {
        'amp' => '&',
        'lt' => '<',
        'gt' => '>',
        'quot' => '"',
        'apos' => "'",
        'nbsp' => ' ',
        _ => match.group(0)!,
      };
    });
  }
}
