import 'package:quran_offline/core/models/tafsir_content.dart';
import 'package:quran_offline/core/tafsir/tafsir_html.dart';

class TafsirContentParser {
  TafsirContentParser._();

  static final _blockPattern = RegExp(
    r'<(p|div)([^>]*)>(.*?)</\1>',
    caseSensitive: false,
    dotAll: true,
  );
  static final _h2Pattern = RegExp(
    r'<h2[^>]*>(.*?)</h2>',
    caseSensitive: false,
    dotAll: true,
  );
  static final _langPattern = RegExp(
    r'''lang=["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _classPattern = RegExp(
    r'''class=["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _labelPattern = RegExp(
    r'^\((\d+)\)\s*',
  );
  static final _metadataPattern = RegExp(
    r'^(makkiyah|madaniyah|madaniyyah|madıniyah)\s*\.?$',
    caseSensitive: false,
  );

  static const _preferredLangs = <String, List<String>>{
    'id': ['id', 'ms'],
    'en': ['en'],
    'zh': ['zh', 'zh-cn', 'zh-hans'],
    'ja': ['ja'],
  };

  static const _excludedLangs = <String, Set<String>>{
    'id': {'jv', 'hi-latn', 'ar', 'en', 'gd'},
    'en': {'jv', 'ar', 'ms', 'id', 'gd'},
    'zh': {'jv', 'en', 'ar', 'ms', 'id', 'gd'},
    'ja': {'jv', 'en', 'ar', 'ms', 'id', 'gd'},
  };

  static TafsirContent parse(String? html, String translationLanguage) {
    final raw = html?.trim() ?? '';
    if (raw.isEmpty) {
      return const TafsirContent(sections: []);
    }

    final segments = _splitByHeadings(raw);
    final sections = <TafsirSection>[];
    String? revelationType;

    for (final segment in segments) {
      final blocks = _extractBlocks(segment.html);
      final paragraphs = <TafsirParagraph>[];

      for (final block in blocks) {
        if (block.classes.contains('translation')) continue;
        if (block.classes.contains('qpc-hafs')) continue;

        final plain = TafsirHtml.polishPlainText(
          TafsirHtml.toPlainText(block.html),
        );
        if (plain.isEmpty) continue;

        if (_metadataPattern.hasMatch(plain)) {
          revelationType ??= _normalizeMetadata(plain);
          continue;
        }

        final lang = block.lang?.toLowerCase();
        if (!_shouldIncludeBlock(lang, block.classes, translationLanguage)) {
          continue;
        }

        final labelMatch = _labelPattern.firstMatch(plain);
        if (labelMatch != null) {
          paragraphs.add(
            TafsirParagraph(
              label: '(${labelMatch.group(1)})',
              text: plain.substring(labelMatch.end).trim(),
            ),
          );
        } else {
          paragraphs.add(TafsirParagraph(text: plain));
        }
      }

      if (paragraphs.isNotEmpty || segment.title != null) {
        sections.add(
          TafsirSection(title: segment.title, paragraphs: paragraphs),
        );
      }
    }

    if (sections.isEmpty) {
      final fallback = TafsirHtml.polishPlainText(TafsirHtml.toPlainText(raw));
      if (fallback.isNotEmpty) {
        sections.add(
          TafsirSection(
            paragraphs: [TafsirParagraph(text: fallback)],
          ),
        );
      }
    }

    return TafsirContent(
      sections: sections,
      revelationType: revelationType,
    );
  }

  static bool _shouldIncludeBlock(
    String? lang,
    String classes,
    String translationLanguage,
  ) {
    if (classes.contains('translation') || classes.contains('qpc-hafs')) {
      return false;
    }

    final normalizedLang = lang?.toLowerCase();
    final excluded = _excludedLangs[translationLanguage] ?? const {};
    if (normalizedLang != null && excluded.contains(normalizedLang)) {
      return false;
    }

    if (normalizedLang != null) {
      final preferred = _preferredLangs[translationLanguage] ??
          [translationLanguage];
      return preferred.contains(normalizedLang);
    }

    return translationLanguage == 'zh' || translationLanguage == 'ja';
  }

  static List<_HtmlSegment> _splitByHeadings(String html) {
    final matches = _h2Pattern.allMatches(html).toList();
    if (matches.isEmpty) {
      return [_HtmlSegment(html: html)];
    }

    final segments = <_HtmlSegment>[];
    var cursor = 0;

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > cursor) {
        final before = html.substring(cursor, match.start);
        if (before.trim().isNotEmpty) {
          segments.add(_HtmlSegment(html: before));
        }
      }

      final title = TafsirHtml.polishPlainText(
        TafsirHtml.toPlainText(match.group(1)),
      );
      final nextStart =
          i + 1 < matches.length ? matches[i + 1].start : html.length;
      final body = html.substring(match.end, nextStart);
      segments.add(
        _HtmlSegment(
          title: title.isEmpty ? null : title,
          html: body,
        ),
      );
      cursor = nextStart;
    }

    return segments;
  }

  static List<_HtmlBlock> _extractBlocks(String html) {
    return _blockPattern
        .allMatches(html)
        .map((match) {
          final attrs = match.group(2) ?? '';
          return _HtmlBlock(
            tag: match.group(1) ?? 'p',
            lang: _langPattern.firstMatch(attrs)?.group(1),
            classes: _classPattern.firstMatch(attrs)?.group(1) ?? '',
            html: match.group(3) ?? '',
          );
        })
        .toList();
  }

  static String _normalizeMetadata(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.startsWith('mad')) return 'Madaniyah';
    return 'Makkiyah';
  }
}

class _HtmlSegment {
  const _HtmlSegment({this.title, this.html = ''});

  final String? title;
  final String html;
}

class _HtmlBlock {
  const _HtmlBlock({
    required this.tag,
    required this.lang,
    required this.classes,
    required this.html,
  });

  final String tag;
  final String? lang;
  final String classes;
  final String html;
}
