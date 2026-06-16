import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/surah_info/surah_info_html.dart';

void main() {
  final idDb = File('assets/quran/surah_info/id_surah_info.sqlite');
  final enDb = File('assets/quran/surah_info/en_surah_info.sqlite');

  test('all 114 Indonesian surah info entries parse consistently', () {
    if (!idDb.existsSync()) return;

    final issues = <String>[];
    for (var surah = 1; surah <= 114; surah++) {
      final row = _queryRow(idDb.path, surah);
      if (row == null) {
        issues.add('surah $surah: missing row');
        continue;
      }

      final entry = SurahInfoHtml.parse(
        html: row.text,
        shortText: row.shortText,
        language: 'id',
      );

      if (entry.isEmpty) {
        issues.add('surah $surah: empty entry');
        continue;
      }

      final expectedSections = _countPokokHeadersInSource(row.text);
      if (expectedSections > 0 && entry.sections.length != expectedSections) {
        issues.add(
          'surah $surah: expected $expectedSections pokok sections, got ${entry.sections.length}',
        );
      }

      for (final section in entry.sections) {
        if (section.title.contains('**') || section.body.contains('**')) {
          issues.add('surah $surah: raw markdown in ${section.title}');
        }
        if (_hubunganTitle.hasMatch(section.title)) {
          issues.add('surah $surah: hubungan as section ${section.title}');
        }
      }

      if (entry.supplementaryBody.contains('**')) {
        issues.add('surah $surah: markdown in supplementary body');
      }
    }

    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('all 114 English surah info entries parse with h2 sections', () {
    if (!enDb.existsSync()) return;

    final issues = <String>[];
    for (var surah = 1; surah <= 114; surah++) {
      final row = _queryRow(enDb.path, surah);
      if (row == null) {
        issues.add('surah $surah: missing row');
        continue;
      }

      final entry = SurahInfoHtml.parse(
        html: row.text,
        shortText: row.shortText,
        language: 'en',
      );

      if (entry.isEmpty) {
        issues.add('surah $surah: empty entry');
        continue;
      }
      if (entry.sections.isEmpty) {
        issues.add('surah $surah: no sections');
      }
    }

    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}

final _hubunganTitle = RegExp(r'hubungan\s+surat', caseSensitive: false);
final _h2Header = RegExp(r'<h2[^>]*>(.*?)</h2>', caseSensitive: false, dotAll: true);
final _mdHeader = RegExp(
  r'<p>\s*(\d+)\.\s*\*\*(Keimanan|Hukum-hukum|Hukum|Kisah-kisah|Kisah|Lain-lain)\s*:?\s*\*\*\s*</p>',
  caseSensitive: false,
);

int _countPokokHeadersInSource(String html) {
  var count = 0;
  for (final match in _h2Header.allMatches(html)) {
    final title = match.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    if (_isPokokLabel(title)) count++;
  }
  count += _mdHeader.allMatches(html).length;
  return count;
}

bool _isPokokLabel(String title) {
  final stripped = title.replaceAll('*', '').trim();
  final match = RegExp(r'^(\d+)\.\s*(.+?)\s*:?\s*$').firstMatch(stripped);
  if (match == null) return false;
  return RegExp(
    r'^(Keimanan|Hukum-hukum|Hukum|Kisah-kisah|Kisah|Lain-lain)$',
    caseSensitive: false,
  ).hasMatch(match.group(2)!.trim());
}

class _Row {
  _Row({required this.text, required this.shortText});
  final String text;
  final String shortText;
}

_Row? _queryRow(String dbPath, int surah) {
  final result = Process.runSync(
    'sqlite3',
    [
      dbPath,
      "SELECT quote(text), quote(COALESCE(short_text, '')) FROM surah_infos WHERE surah_number=$surah;",
    ],
  );
  if (result.exitCode != 0) return null;
  final line = (result.stdout as String).trim();
  if (line.isEmpty) return null;
  final parts = line.split('|');
  if (parts.length != 2) return null;
  return _Row(
    text: _unquote(parts[0]),
    shortText: _unquote(parts[1]),
  );
}

String _unquote(String quoted) {
  if (quoted.length < 2) return quoted;
  var value = quoted.substring(1, quoted.length - 1);
  value = value.replaceAll("''", "'");
  return value;
}
