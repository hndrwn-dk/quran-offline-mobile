import 'package:quran_offline/core/models/asma_entry.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

enum ExploreSearchKind { dua, science, theme, asma }

class ExploreSearchHit {
  const ExploreSearchHit({
    required this.kind,
    required this.sectionKey,
    required this.title,
    required this.subtitle,
    this.dua,
    this.science,
    this.theme,
    this.asma,
  });

  final ExploreSearchKind kind;
  final String sectionKey;
  final String title;
  final String subtitle;
  final DuaEntry? dua;
  final ScienceEntry? science;
  final ThemeEntry? theme;
  final AsmaEntry? asma;
}

bool exploreLocalizedTextMatches(LocalizedText text, String queryLower) {
  return text.id.toLowerCase().contains(queryLower) ||
      text.en.toLowerCase().contains(queryLower) ||
      text.zh.toLowerCase().contains(queryLower) ||
      text.ja.toLowerCase().contains(queryLower);
}

bool explorePlainMatches(String? value, String queryLower) {
  if (value == null || value.isEmpty) return false;
  return value.toLowerCase().contains(queryLower);
}

String _duaSectionKey(DuaEntry entry) {
  if (entry.category == 'prophet') return 'prophet';
  if (entry.category == 'daily') return 'life_theme';
  return entry.category;
}

String _duaSubtitle(DuaEntry entry, String lang) {
  if (entry.category == 'daily' && entry.theme != null) {
    return AppLocalizations.getThemeCategoryLabel(entry.theme!, lang);
  }
  if (entry.category == 'prophet' && entry.prophet != null) {
    return AppLocalizations.getDuaProphetName(entry.prophet!, lang);
  }
  return AppLocalizations.getDuaCategoryLabel(_duaSectionKey(entry), lang);
}

String _ayahRefLabel(DuaAyahRef ref, String lang) {
  return AppLocalizations.formatDuaAyahRef(ref.surah, ref.from, ref.to, lang);
}

List<ExploreSearchHit> searchExploreContent({
  required String query,
  required String lang,
  required DuaCatalog duaCatalog,
  AsmaCatalog? asmaCatalog,
  ScienceCatalog? scienceCatalog,
  ThemeCatalog? themeCatalog,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];

  final hits = <ExploreSearchHit>[];

  for (final entry in duaCatalog.entries) {
    final sectionKey = _duaSectionKey(entry);
    final prophetName = entry.prophet != null
        ? AppLocalizations.getDuaProphetName(entry.prophet!, lang)
        : null;
    final categoryLabel = entry.theme != null
        ? AppLocalizations.getThemeCategoryLabel(entry.theme!, lang)
        : null;
    final matches = exploreLocalizedTextMatches(entry.title, q) ||
        exploreLocalizedTextMatches(entry.summary, q) ||
        explorePlainMatches(prophetName, q) ||
        explorePlainMatches(categoryLabel, q) ||
        explorePlainMatches(
          AppLocalizations.getDuaCategoryLabel(sectionKey, lang),
          q,
        );
    if (!matches) continue;
    hits.add(
      ExploreSearchHit(
        kind: ExploreSearchKind.dua,
        sectionKey: sectionKey,
        title: entry.title.forLanguage(lang),
        subtitle: _duaSubtitle(entry, lang),
        dua: entry,
      ),
    );
  }

  final science = scienceCatalog;
  if (science != null) {
    for (final entry in science.entries) {
      final categoryLabel =
          AppLocalizations.getScienceCategoryLabel(entry.category, lang);
      final matches = exploreLocalizedTextMatches(entry.title, q) ||
          exploreLocalizedTextMatches(entry.summary, q) ||
          exploreLocalizedTextMatches(entry.scienceNote, q) ||
          explorePlainMatches(categoryLabel, q);
      if (!matches) continue;
      hits.add(
        ExploreSearchHit(
          kind: ExploreSearchKind.science,
          sectionKey: 'science',
          title: entry.title.forLanguage(lang),
          subtitle: '$categoryLabel · ${_ayahRefLabel(entry.primaryRef, lang)}',
          science: entry,
        ),
      );
    }
  }

  final theme = themeCatalog;
  if (theme != null) {
    for (final entry in theme.entries) {
      final categoryLabel =
          AppLocalizations.getThemeCategoryLabel(entry.category, lang);
      final matches = exploreLocalizedTextMatches(entry.title, q) ||
          exploreLocalizedTextMatches(entry.summary, q) ||
          exploreLocalizedTextMatches(entry.reflection, q) ||
          explorePlainMatches(categoryLabel, q);
      if (!matches) continue;
      hits.add(
        ExploreSearchHit(
          kind: ExploreSearchKind.theme,
          sectionKey: 'life_theme',
          title: entry.title.forLanguage(lang),
          subtitle: '$categoryLabel · ${_ayahRefLabel(entry.primaryRef, lang)}',
          theme: entry,
        ),
      );
    }
  }

  final asma = asmaCatalog;
  if (asma != null) {
    for (final entry in asma.entries) {
      final matches = exploreLocalizedTextMatches(entry.title, q) ||
          exploreLocalizedTextMatches(entry.summary, q) ||
          exploreLocalizedTextMatches(entry.reflection, q) ||
          explorePlainMatches(entry.transliteration, q) ||
          explorePlainMatches(entry.arabic, q) ||
          explorePlainMatches('${entry.number}', q);
      if (!matches) continue;
      hits.add(
        ExploreSearchHit(
          kind: ExploreSearchKind.asma,
          sectionKey: 'asma',
          title: entry.transliteration,
          subtitle:
              '${entry.title.forLanguage(lang)} · ${_ayahRefLabel(entry.primaryRef, lang)}',
          asma: entry,
        ),
      );
    }
  }

  return hits;
}
