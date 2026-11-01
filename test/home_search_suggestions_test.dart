import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/home/home_search_suggestions.dart';

const _catalogPath = 'assets/ai/quran_dua_ayat_catalog.json';
const _quranDir = 'assets/quran';

Set<String> _catalogTags() {
  final data =
      jsonDecode(File(_catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final entries = data['entries'] as List<dynamic>;
  return {
    for (final entry in entries.cast<Map<String, dynamic>>())
      ...(entry['tags'] as List<dynamic>).cast<String>(),
  };
}

Map<String, List<String>> _translationsByLanguage() {
  final translations = <String, List<String>>{
    'id': [],
    'en': [],
    'zh': [],
    'ja': [],
  };
  final files = Directory(_quranDir)
      .listSync()
      .whereType<File>()
      .where((file) => RegExp(r's\d{3}\.json$').hasMatch(file.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final verses = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    for (final verse in verses.cast<Map<String, dynamic>>()) {
      final tr = verse['tr'] as Map<String, dynamic>;
      for (final lang in translations.keys) {
        translations[lang]!.add((tr[lang] as String? ?? '').toLowerCase());
      }
    }
  }
  return translations;
}

void main() {
  test('every Home search suggestion is backed by a reviewed dua tag', () {
    final tags = _catalogTags();
    expect(homeSearchSuggestions, isNotEmpty);
    for (final suggestion in homeSearchSuggestions) {
      expect(
        tags.contains(suggestion.tag),
        isTrue,
        reason: 'Tag "${suggestion.tag}" is not in $_catalogPath',
      );
    }
  });

  test('every localized chip query returns at least one verse', () {
    final translations = _translationsByLanguage();

    for (final lang in ['id', 'en', 'zh', 'ja']) {
      for (final suggestion in homeSearchSuggestions) {
        final label = suggestion.label(lang);
        final query = suggestion.query(lang);
        expect(label.trim(), isNotEmpty, reason: 'Missing $lang label');
        expect(query.trim(), isNotEmpty, reason: 'Missing $lang query');

        final needle = query.toLowerCase();
        final hits = translations[lang]!
            .where((translation) => translation.contains(needle))
            .length;
        expect(
          hits,
          greaterThan(0),
          reason:
              'Chip "${suggestion.tag}" ($lang) query "$query" returned no '
              'results',
        );
      }
    }
  });

  test('Indonesian chip copy uses "kamu" and never "Anda"', () {
    for (final suggestion in homeSearchSuggestions) {
      final label = suggestion.label('id');
      final query = suggestion.query('id');
      expect(RegExp('anda', caseSensitive: false).hasMatch(label), isFalse);
      expect(RegExp('anda', caseSensitive: false).hasMatch(query), isFalse);
    }
    final placeholder = AppLocalizations.getHomeSearchPlaceholder('id');
    expect(placeholder, contains('kamu'));
    expect(RegExp('anda', caseSensitive: false).hasMatch(placeholder), isFalse);
  });
}
