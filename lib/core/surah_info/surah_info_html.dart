import 'package:quran_offline/core/models/surah_qul_info.dart';
import 'package:quran_offline/core/tafsir/tafsir_html.dart';

/// Parses QUL surah info HTML into a consistent structure for the reader UI.
class SurahInfoHtml {
  SurahInfoHtml._();

  static final _h2Pattern = RegExp(
    r'<h2[^>]*>(.*?)</h2>',
    caseSensitive: false,
    dotAll: true,
  );
  static final _paragraphPattern = RegExp(
    r'<p[^>]*>(.*?)</p>',
    caseSensitive: false,
    dotAll: true,
  );
  static final _pokokMarkerPattern = RegExp(
    r'<h[1-3][^>]*>\s*Pokok',
    caseSensitive: false,
    dotAll: true,
  );
  static final _pokokPokokLabels = RegExp(
    r'^(Keimanan|Hukum-hukum|Hukum|Kisah-kisah|Kisah|Lain-lain)\s*:?\s*$',
    caseSensitive: false,
  );
  static final _boldHeaderTitle = RegExp(
    r'^\s*\*{2}(.+?)\*{2}:?\s*$',
  );
  static final _pokokPokokHeader = RegExp(
    r'pokok[-\s]*pokok\s*isi',
    caseSensitive: false,
  );
  static final _hubunganSuratHeader = RegExp(
    r'hubungan\s+surat\b',
    caseSensitive: false,
  );
  static final _h3HubunganPattern = RegExp(
    r'<h3[^>]*>\s*(Hubungan[^<]*)</h3>',
    caseSensitive: false,
    dotAll: true,
  );

  static SurahQulInfoEntry parse({
    required String? html,
    required String? shortText,
    required String language,
  }) {
    final rawHtml = html?.trim() ?? '';
    if (language == 'id') {
      return _parseIndonesian(rawHtml: rawHtml, shortText: shortText);
    }
    return _parseEnglish(rawHtml: rawHtml, shortText: shortText);
  }

  static SurahQulInfoEntry _parseIndonesian({
    required String rawHtml,
    required String? shortText,
  }) {
    var short = _resolveShort(rawHtml, shortText, language: 'id');
    final pokokSections = _extractFourPokokSections(rawHtml);

    if (pokokSections.isNotEmpty) {
      return SurahQulInfoEntry(
        short: short,
        sections: pokokSections,
      );
    }

    final supplementary = _extractSupplementaryBody(rawHtml);
    if (supplementary.isNotEmpty) {
      return SurahQulInfoEntry(
        short: short,
        sections: const [],
        supplementaryBody: supplementary,
      );
    }

    if (rawHtml.isNotEmpty) {
      final body = _cleanText(TafsirHtml.toPlainText(rawHtml));
      if (body.isNotEmpty) {
        return SurahQulInfoEntry(
          short: short.isNotEmpty ? short : body,
          sections: const [],
        );
      }
    }

    return SurahQulInfoEntry(short: short, sections: const []);
  }

  static SurahQulInfoEntry _parseEnglish({
    required String rawHtml,
    required String? shortText,
  }) {
    final short = _resolveShort(rawHtml, shortText, language: 'en');
    final sections = rawHtml.isNotEmpty ? _parseEnglishH2Sections(rawHtml) : <SurahQulInfoSection>[];
    return SurahQulInfoEntry(short: short, sections: sections);
  }

  static String _resolveShort(
    String rawHtml,
    String? shortText, {
    required String language,
  }) {
    final trimmedShort = shortText?.trim() ?? '';
    if (trimmedShort.isNotEmpty) {
      return _cleanText(TafsirHtml.toPlainText(trimmedShort));
    }
    if (language == 'id' && rawHtml.isNotEmpty) {
      return _extractIntro(rawHtml);
    }
    return '';
  }

  static List<SurahQulInfoSection> _extractFourPokokSections(String rawHtml) {
    if (_hasPokokH2Sections(rawHtml)) {
      return _parsePokokFromH2(rawHtml);
    }
    return _parsePokokFromParagraphs(rawHtml);
  }

  static bool _hasPokokH2Sections(String rawHtml) {
    return _h2Pattern.allMatches(rawHtml).any((match) {
      final title = TafsirHtml.toPlainText(match.group(1)).trim();
      return _matchPokokLabel(title) != null;
    });
  }

  static List<SurahQulInfoSection> _parsePokokFromH2(String rawHtml) {
    final h2Matches = _h2Pattern.allMatches(rawHtml).toList();
    final sections = <SurahQulInfoSection>[];

    for (var i = 0; i < h2Matches.length; i++) {
      final titlePlain = TafsirHtml.toPlainText(h2Matches[i].group(1)).trim();
      final pokok = _matchPokokLabel(titlePlain);
      if (pokok == null) continue;

      final start = h2Matches[i].end;
      final end =
          i + 1 < h2Matches.length ? h2Matches[i + 1].start : rawHtml.length;
      var body = _cleanText(TafsirHtml.toPlainText(rawHtml.substring(start, end)));
      body = _stripHubunganH3Prefix(body, rawHtml.substring(start, end));

      sections.add(
        SurahQulInfoSection(
          title: '${pokok.$1}. ${pokok.$2}:',
          body: body,
        ),
      );
    }

    _mergeHubunganIntoLastSection(sections, rawHtml);
    return sections;
  }

  static String _stripHubunganH3Prefix(String plainBody, String htmlFragment) {
    final h3 = _h3HubunganPattern.firstMatch(htmlFragment);
    if (h3 == null) return plainBody;

    final heading = _formatHubunganHeading(
      _cleanText(TafsirHtml.toPlainText(h3.group(1))),
    );
    if (plainBody.contains(heading)) return plainBody;
    return _joinBody(heading, plainBody);
  }

  static void _mergeHubunganIntoLastSection(
    List<SurahQulInfoSection> sections,
    String rawHtml,
  ) {
    if (sections.isEmpty) return;
    final last = sections.last;
    if (_hubunganSuratHeader.hasMatch(last.body)) return;

    final h3 = _h3HubunganPattern.firstMatch(rawHtml);
    if (h3 == null) return;

    final hubunganStart = h3.start;
    final lastH2 = _lastPokokH2End(rawHtml);
    if (lastH2 == null || hubunganStart < lastH2) return;

    final hubunganHtml = rawHtml.substring(hubunganStart);
    final hubunganPlain = _cleanText(TafsirHtml.toPlainText(hubunganHtml));
    if (hubunganPlain.isEmpty) return;
    if (last.body.contains(hubunganPlain)) return;

    sections[sections.length - 1] = SurahQulInfoSection(
      title: last.title,
      body: _joinBody(last.body, hubunganPlain),
    );
  }

  static int? _lastPokokH2End(String rawHtml) {
    int? lastEnd;
    for (final match in _h2Pattern.allMatches(rawHtml)) {
      final title = TafsirHtml.toPlainText(match.group(1)).trim();
      if (_matchPokokLabel(title) != null) {
        lastEnd = match.end;
      }
    }
    return lastEnd;
  }

  static List<SurahQulInfoSection> _parsePokokFromParagraphs(String rawHtml) {
    final paragraphs = _extractParagraphs(rawHtml);
    if (paragraphs.isEmpty) return [];

    final sections = <SurahQulInfoSection>[];
    SurahQulInfoSection? current;
    var insideHubungan = false;
    var foundPokok = false;

    void flushCurrent() {
      if (current == null) return;
      if (current!.title.isNotEmpty || current!.body.isNotEmpty) {
        sections.add(current!);
      }
      current = null;
    }

    for (final paragraph in paragraphs) {
      if (_isPokokMarkerParagraph(paragraph)) {
        foundPokok = true;
        continue;
      }

      if (!insideHubungan) {
        final pokok = _matchPokokSectionFromParagraph(paragraph);
        if (pokok != null) {
          foundPokok = true;
          flushCurrent();
          current = SurahQulInfoSection(
            title: '${pokok.$1}. ${pokok.$2}:',
            body: '',
          );
          continue;
        }
      }

      final boldHeader = _boldHeaderTitle.firstMatch(paragraph);
      if (boldHeader != null) {
        final header = _cleanText(boldHeader.group(1)!);
        if (_pokokPokokHeader.hasMatch(header)) {
          foundPokok = true;
          continue;
        }
        if (_hubunganSuratHeader.hasMatch(header)) {
          insideHubungan = true;
          _appendToCurrent(
            sections: sections,
            current: current,
            text: _formatHubunganHeading(header),
            onUpdate: (section) => current = section,
          );
          continue;
        }
      }

      if (!_paragraphBelongsInSections(paragraph, foundPokok: foundPokok)) {
        continue;
      }

      if (current != null) {
        current = SurahQulInfoSection(
          title: current!.title,
          body: _joinBody(current!.body, _cleanText(paragraph)),
        );
      }
    }

    flushCurrent();
    return sections;
  }

  static bool _paragraphBelongsInSections(String paragraph, {required bool foundPokok}) {
    if (!foundPokok) return false;
    if (_isPokokMarkerParagraph(paragraph)) return false;
    if (_matchPokokSectionFromParagraph(paragraph) != null) return false;
    return true;
  }

  static String _extractSupplementaryBody(String rawHtml) {
    final paragraphs = _extractParagraphs(rawHtml);
    if (paragraphs.isEmpty) return '';

    final buffer = <String>[];
    var afterPokokMarker = false;

    for (final paragraph in paragraphs) {
      if (_isPokokMarkerParagraph(paragraph)) {
        afterPokokMarker = true;
        continue;
      }

      if (!afterPokokMarker) continue;

      if (_matchPokokSectionFromParagraph(paragraph) != null) continue;

      final boldHeader = _boldHeaderTitle.firstMatch(paragraph);
      if (boldHeader != null) {
        final header = _cleanText(boldHeader.group(1)!);
        if (_pokokPokokHeader.hasMatch(header)) continue;
        if (_hubunganSuratHeader.hasMatch(header)) {
          buffer.add(_formatHubunganHeading(header));
          continue;
        }
      }

      buffer.add(_cleanText(paragraph));
    }

    return buffer.join('\n\n').trim();
  }

  static String _extractIntro(String rawHtml) {
    final marker = _pokokMarkerPattern.firstMatch(rawHtml);
    if (marker != null && marker.start > 0) {
      return _cleanText(
        TafsirHtml.toPlainText(rawHtml.substring(0, marker.start)),
      );
    }

    for (final match in _h2Pattern.allMatches(rawHtml)) {
      final title = TafsirHtml.toPlainText(match.group(1)).trim();
      if (_matchPokokLabel(title) != null && match.start > 0) {
        return _cleanText(
          TafsirHtml.toPlainText(rawHtml.substring(0, match.start)),
        );
      }
    }

    return _introFromParagraphs(rawHtml);
  }

  static List<SurahQulInfoSection> _parseEnglishH2Sections(String rawHtml) {
    final h2Matches = _h2Pattern.allMatches(rawHtml).toList();
    final sections = <SurahQulInfoSection>[];

    for (var i = 0; i < h2Matches.length; i++) {
      final title = _cleanText(TafsirHtml.toPlainText(h2Matches[i].group(1)));
      final start = h2Matches[i].end;
      final end =
          i + 1 < h2Matches.length ? h2Matches[i + 1].start : rawHtml.length;
      final body = _cleanText(TafsirHtml.toPlainText(rawHtml.substring(start, end)));
      if (title.isNotEmpty || body.isNotEmpty) {
        sections.add(
          SurahQulInfoSection(title: title.trim(), body: body.trim()),
        );
      }
    }

    return sections;
  }

  static List<String> _extractParagraphs(String html) {
    return _paragraphPattern
        .allMatches(html)
        .map((match) => TafsirHtml.toPlainText(match.group(1)).trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  static String _introFromParagraphs(String html) {
    final paragraphs = _extractParagraphs(html);
    final intro = <String>[];

    for (final paragraph in paragraphs) {
      if (_isPokokMarkerParagraph(paragraph)) break;
      if (_matchPokokSectionFromParagraph(paragraph) != null) break;
      if (_boldHeaderTitle.hasMatch(paragraph)) {
        final header = _boldHeaderTitle.firstMatch(paragraph)!.group(1)!;
        if (_pokokPokokHeader.hasMatch(header)) break;
        break;
      }
      intro.add(_cleanText(paragraph));
    }

    return intro.join('\n\n');
  }

  static bool _isPokokMarkerParagraph(String paragraph) {
    final stripped = paragraph.replaceAll('*', '').trim();
    return _pokokPokokHeader.hasMatch(stripped);
  }

  static (String, String)? _matchPokokSectionFromParagraph(String paragraph) {
    return _matchPokokLabel(paragraph.replaceAll('*', '').trim());
  }

  static (String, String)? _matchPokokLabel(String text) {
    final stripped = text.replaceAll('*', '').trim();
    final match = RegExp(r'^(\d+)\.\s*(.+?)\s*:?\s*$').firstMatch(stripped);
    if (match == null) return null;
    final label = match.group(2)!.trim();
    if (!_pokokPokokLabels.hasMatch(label)) return null;
    final cleanLabel = label.replaceAll(RegExp(r':\s*$'), '').trim();
    return (match.group(1)!, cleanLabel);
  }

  static String _joinBody(String existing, String next) {
    if (existing.isEmpty) return next;
    return '$existing\n\n$next';
  }

  static String _formatHubunganHeading(String header) {
    final trimmed = header.trim();
    if (trimmed.endsWith(':')) return trimmed;
    return '$trimmed:';
  }

  static void _appendToCurrent({
    required List<SurahQulInfoSection> sections,
    required SurahQulInfoSection? current,
    required String text,
    required void Function(SurahQulInfoSection section) onUpdate,
  }) {
    if (current != null) {
      onUpdate(
        SurahQulInfoSection(
          title: current.title,
          body: _joinBody(current.body, text),
        ),
      );
      return;
    }

    if (sections.isNotEmpty) {
      final last = sections.removeLast();
      sections.add(
        SurahQulInfoSection(
          title: last.title,
          body: _joinBody(last.body, text),
        ),
      );
    }
  }

  static String _cleanText(String? text) {
    if (text == null) return '';
    var cleaned = text.replaceAll('\t', ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\*+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }
}
