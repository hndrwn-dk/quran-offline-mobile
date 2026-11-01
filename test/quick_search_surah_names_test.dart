import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/quick_search_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';

import 'support/mushaf_real_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeSurahNameForSearch', () {
    test('drops case, spaces, hyphens and apostrophes', () {
      expect(normalizeSurahNameForSearch('Ya-Sin'), 'yasin');
      expect(normalizeSurahNameForSearch('ya sin'), 'yasin');
      expect(normalizeSurahNameForSearch("'Abasa"), 'abasa');
      expect(normalizeSurahNameForSearch('’Abasa'), 'abasa');
      expect(normalizeSurahNameForSearch('ʿAbasa'), 'abasa');
      expect(normalizeSurahNameForSearch('Al-Mutaffifin'), 'almutaffifin');
      expect(normalizeSurahNameForSearch(' - '), '');
    });
  });

  group('quick search finds surahs by loose names', () {
    Future<List<int>> surahIdsFor(String query) async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) => StaticTestSettings()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(surahNamesProvider.future);
      container.read(quickSearchQueryProvider.notifier).state = query;
      final results = await container.read(quickSearchResultsProvider.future);
      return [
        for (final r in results)
          if (r.type == 'surah') (r.source as SurahSource).surahId,
      ];
    }

    for (final (query, surahId) in const [
      ('yasin', 36),
      ('ya sin', 36),
      ('Ya-Sin', 36),
      ('abasa', 80),
      ("'abasa", 80),
      ('almutaffifin', 83),
      ('al mutaffifin', 83),
    ]) {
      test('"$query" finds surah $surahId', () async {
        expect(await surahIdsFor(query), contains(surahId));
      });
    }

    test('punctuation alone matches no surah', () async {
      expect(await surahIdsFor('-'), isEmpty);
    });
  });
}
