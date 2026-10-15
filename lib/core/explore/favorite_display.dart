import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:quran_offline/core/models/asma_entry.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

enum FavoriteAccent { green, sand, blue }

class FavoriteDisplay {
  const FavoriteDisplay({
    required this.favorite,
    required this.title,
    required this.categoryLabel,
    required this.sourceLabel,
    required this.qsLabel,
    required this.accent,
    required this.iconSection,
    this.catalogArabic,
    this.snippetSurah,
    this.snippetAyah,
  });

  final ExploreFavorite favorite;
  final String title;
  final String categoryLabel;
  final String sourceLabel;
  final String? qsLabel;
  final FavoriteAccent accent;
  final String iconSection;
  final String? catalogArabic;
  final int? snippetSurah;
  final int? snippetAyah;

  String get eyebrow {
    if (sourceLabel.isEmpty) return categoryLabel;
    return '$categoryLabel · $sourceLabel';
  }
}

List<FavoriteDisplay> resolveFavoriteDisplays({
  required List<ExploreFavorite> favorites,
  required String lang,
  required List<DuaEntry> duas,
  required List<ScienceEntry> science,
  required List<AsmaEntry> asma,
  required List<ThemeEntry> themes,
}) {
  final displays = <FavoriteDisplay>[];
  for (final favorite in favorites) {
    final display = resolveFavoriteDisplay(
      favorite: favorite,
      lang: lang,
      duas: duas,
      science: science,
      asma: asma,
      themes: themes,
    );
    if (display != null) displays.add(display);
  }
  return displays;
}

FavoriteDisplay? resolveFavoriteDisplay({
  required ExploreFavorite favorite,
  required String lang,
  required List<DuaEntry> duas,
  required List<ScienceEntry> science,
  required List<AsmaEntry> asma,
  required List<ThemeEntry> themes,
}) {
  switch (favorite.kind) {
    case ExploreFavoriteKind.dua:
      for (final entry in duas) {
        if (entry.id != favorite.id) continue;
        final prophet = entry.category == 'prophet';
        return FavoriteDisplay(
          favorite: favorite,
          title: entry.title.forLanguage(lang),
          categoryLabel: AppLocalizations.getDuaCategoryLabel(
            prophet ? 'prophet' : 'daily',
            lang,
          ),
          sourceLabel: prophet
              ? (entry.prophet == null
                  ? ''
                  : AppLocalizations.getDuaProphetName(entry.prophet!, lang))
              : (entry.theme == null || entry.theme!.isEmpty
                  ? ''
                  : AppLocalizations.getThemeCategoryLabel(entry.theme!, lang)),
          qsLabel: _qsLabel(favorite.kind, entry.ayahRefs, lang),
          accent: FavoriteAccent.green,
          iconSection: 'prophet',
          snippetSurah: entry.ayahRefs.isEmpty ? null : entry.primaryRef.surah,
          snippetAyah: entry.ayahRefs.isEmpty ? null : entry.primaryRef.from,
        );
      }
      return null;
    case ExploreFavoriteKind.science:
      for (final entry in science) {
        if (entry.id != favorite.id) continue;
        return FavoriteDisplay(
          favorite: favorite,
          title: entry.title.forLanguage(lang),
          categoryLabel: AppLocalizations.getDuaCategoryLabel('science', lang),
          sourceLabel: AppLocalizations.getScienceCategoryLabel(
            entry.category,
            lang,
          ),
          qsLabel: _qsLabel(favorite.kind, entry.ayahRefs, lang),
          accent: FavoriteAccent.blue,
          iconSection: 'science',
          snippetSurah: entry.ayahRefs.isEmpty ? null : entry.primaryRef.surah,
          snippetAyah: entry.ayahRefs.isEmpty ? null : entry.primaryRef.from,
        );
      }
      return null;
    case ExploreFavoriteKind.asma:
      for (final entry in asma) {
        if (entry.id != favorite.id) continue;
        return FavoriteDisplay(
          favorite: favorite,
          title: entry.title.forLanguage(lang),
          categoryLabel: AppLocalizations.getDuaCategoryLabel('asma', lang),
          sourceLabel: AppLocalizations.getExploreFavoriteAsmaSource(
            entry.number,
            lang,
          ),
          qsLabel: null,
          accent: FavoriteAccent.sand,
          iconSection: 'asma',
          catalogArabic: entry.arabic,
        );
      }
      return null;
    case ExploreFavoriteKind.theme:
      for (final entry in themes) {
        if (entry.id != favorite.id) continue;
        return FavoriteDisplay(
          favorite: favorite,
          title: entry.title.forLanguage(lang),
          categoryLabel:
              AppLocalizations.getDuaCategoryLabel('life_theme', lang),
          sourceLabel: AppLocalizations.getThemeCategoryLabel(
            entry.category,
            lang,
          ),
          qsLabel: _qsLabel(favorite.kind, entry.ayahRefs, lang),
          accent: FavoriteAccent.green,
          iconSection: 'life_theme',
          snippetSurah: entry.ayahRefs.isEmpty ? null : entry.primaryRef.surah,
          snippetAyah: entry.ayahRefs.isEmpty ? null : entry.primaryRef.from,
        );
      }
      return null;
  }
}

String? _qsLabel(
  ExploreFavoriteKind kind,
  List<DuaAyahRef> refs,
  String lang,
) {
  if (kind == ExploreFavoriteKind.asma || refs.isEmpty) return null;
  final first = refs.first;
  final label = AppLocalizations.formatDuaAyahRef(
    first.surah,
    first.from,
    first.to,
    lang,
  );
  if (refs.length == 1) return label;
  return '$label +${refs.length - 1}';
}
