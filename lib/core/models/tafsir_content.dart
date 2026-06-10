class TafsirParagraph {
  const TafsirParagraph({
    this.label,
    required this.text,
  });

  final String? label;
  final String text;
}

class TafsirSection {
  const TafsirSection({
    this.title,
    required this.paragraphs,
  });

  final String? title;
  final List<TafsirParagraph> paragraphs;

  bool get isEmpty =>
      paragraphs.every((p) => p.text.trim().isEmpty) &&
      (title == null || title!.trim().isEmpty);
}

class TafsirContent {
  const TafsirContent({
    required this.sections,
    this.revelationType,
  });

  final List<TafsirSection> sections;
  final String? revelationType;

  bool get isEmpty => sections.every((s) => s.isEmpty);

  String get plainText {
    final buffer = StringBuffer();
    for (final section in sections) {
      if (section.title != null && section.title!.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln(section.title!.trim());
        buffer.writeln();
      }
      for (final paragraph in section.paragraphs) {
        if (paragraph.label != null && paragraph.label!.trim().isNotEmpty) {
          buffer.write('${paragraph.label!.trim()} ');
        }
        buffer.writeln(paragraph.text.trim());
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }
}
