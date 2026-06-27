import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

void main() {
  const langs = ['id', 'en', 'zh', 'ja'];

  group('Jelajahi menu l10n', () {
    for (final lang in langs) {
      test('tab labels and subtitle for $lang', () {
        expect(AppLocalizations.getMenuText('dua', lang), isNotEmpty);
        expect(AppLocalizations.getSubtitleText('dua_subtitle', lang), isNotEmpty);

        for (final cat in ['daily', 'prophet', 'science', 'asma', 'life_theme']) {
          final label = AppLocalizations.getDuaCategoryLabel(cat, lang);
          expect(label, isNotEmpty, reason: 'category $cat');
          expect(label, isNot(cat), reason: 'untranslated key $cat');
          expect(
            AppLocalizations.getExploreHubHint(cat, lang),
            isNotEmpty,
            reason: 'hub hint $cat',
          );
        }
        expect(AppLocalizations.getAsmaNamesCount(99, lang), contains('99'));
        expect(
          AppLocalizations.formatExploreDrillSubtitle('8 topik', 'Sains'),
          '8 topik · Sains',
        );
        expect(AppLocalizations.getExploreSearchHint(lang), isNotEmpty);
        expect(AppLocalizations.getExploreSearchEmpty(lang), isNotEmpty);
      });

      test('science and theme helpers for $lang', () {
        expect(AppLocalizations.getScienceNoteHeading(lang), isNotEmpty);
        expect(AppLocalizations.getThemeReflectionHeading(lang), isNotEmpty);
        expect(AppLocalizations.getAsmaReflectionHeading(lang), isNotEmpty);
        expect(AppLocalizations.getScienceLoadError(lang), isNotEmpty);
        expect(AppLocalizations.getAsmaLoadError(lang), isNotEmpty);
        expect(AppLocalizations.getThemeLoadError(lang), isNotEmpty);
        expect(AppLocalizations.getCatalogRetry(lang), isNotEmpty);
        expect(AppLocalizations.getExploreScrollHint(lang), isNotEmpty);
        expect(AppLocalizations.getDuaOpenInReader(lang), isNotEmpty);

        for (final cat in ['cosmos', 'biology', 'earth', 'physics']) {
          expect(
            AppLocalizations.getScienceCategoryLabel(cat, lang),
            isNotEmpty,
          );
        }
        for (final cat in [
          'forgiveness',
          'faith',
          'patience',
          'trials',
          'protection',
          'provision',
          'family',
          'gratitude',
          'hope',
          'character',
          'world_hereafter',
          'hereafter',
        ]) {
          expect(
            AppLocalizations.getThemeCategoryLabel(cat, lang),
            isNotEmpty,
          );
        }
        if (lang == 'id') {
          expect(
            AppLocalizations.getThemeCategoryLabel('hereafter', lang),
            AppLocalizations.getThemeCategoryLabel('world_hereafter', lang),
          );
          expect(
            AppLocalizations.getLifeSituationHubCount(31, 16, lang),
            '31 doa · 16 renungan',
          );
        }
        for (final theme in [
          'forgiveness',
          'faith',
          'trials',
          'protection',
          'provision',
          'family',
          'gratitude',
          'world_hereafter',
        ]) {
          expect(
            AppLocalizations.getDailyThemeLabel(theme, lang),
            isNotEmpty,
            reason: 'daily theme $theme',
          );
        }
        if (lang == 'id') {
          expect(
            AppLocalizations.getDailyThemeLabel('world_hereafter', lang),
            'Kebaikan dunia & akhirat',
          );
        }
      });

      test('reflection card l10n for $lang', () {
        expect(
          AppLocalizations.getReflectionCardTitle('weekly', lang),
          isNotEmpty,
        );
        expect(
          AppLocalizations.getReflectionCardTitle('calendar', lang),
          isNotEmpty,
        );
        expect(AppLocalizations.getReflectionContextLabel(lang), isNotEmpty);
        expect(
          AppLocalizations.getReflectionBadge('friday', lang),
          isNotEmpty,
        );
        expect(
          AppLocalizations.getReflectionBadge('ramadan', lang),
          isNotEmpty,
        );
        expect(
          AppLocalizations.getReflectionBadge('weekly', lang),
          isNotEmpty,
        );
      });
    }
  });

  test('Jelajahi menu name differs per language', () {
    final id = AppLocalizations.getMenuText('dua', 'id');
    final en = AppLocalizations.getMenuText('dua', 'en');
    final zh = AppLocalizations.getMenuText('dua', 'zh');
    final ja = AppLocalizations.getMenuText('dua', 'ja');
    expect(id, 'Jelajahi');
    expect(en, 'Explore');
    expect(zh, '探索');
    expect(ja, '探求');
    expect({id, en, zh, ja}.length, 4);
  });
}
