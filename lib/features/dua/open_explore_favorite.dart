import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/explore_favorites_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/dua/widgets/explore_section_scaffold.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

Future<void> openExploreFavoritesPage(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => const ExploreFavoritesPage(),
    ),
  );
}

Future<void> openExploreFavorite(
  BuildContext context,
  WidgetRef ref,
  ExploreFavorite favorite,
) async {
  final lang = ref.read(settingsProvider).appLanguage;
  switch (favorite.kind) {
    case ExploreFavoriteKind.dua:
      final catalog = await ref.read(duaCatalogProvider.future);
      for (final entry in catalog.entries) {
        if (entry.id != favorite.id || !context.mounted) continue;
        await showExploreDetailSheet(
          context: context,
          ref: ref,
          lang: lang,
          title: entry.title,
          summary: entry.summary,
          ayahRefs: entry.ayahRefs,
          favoriteKind: ExploreFavoriteKind.dua,
          favoriteId: entry.id,
          onOpenReader: (ayahRef) {
            openReaderFromAyahRef(ref, ayahRef);
            openReaderScreen(context, ref);
          },
        );
        return;
      }
      return;
    case ExploreFavoriteKind.science:
      final catalog = await ref.read(scienceCatalogProvider.future);
      for (final entry in catalog.entries) {
        if (entry.id != favorite.id || !context.mounted) continue;
        await showExploreDetailSheet(
          context: context,
          ref: ref,
          lang: lang,
          title: entry.title,
          summary: entry.summary,
          sectionNote: entry.scienceNote,
          sectionHeading: AppLocalizations.getScienceNoteHeading(lang),
          ayahRefs: entry.ayahRefs,
          favoriteKind: ExploreFavoriteKind.science,
          favoriteId: entry.id,
          onOpenReader: (ayahRef) {
            openReaderFromAyahRef(ref, ayahRef);
            openReaderScreen(context, ref);
          },
        );
        return;
      }
      return;
    case ExploreFavoriteKind.asma:
      final catalog = await ref.read(asmaCatalogProvider.future);
      for (final entry in catalog.entries) {
        if (entry.id != favorite.id || !context.mounted) continue;
        await showExploreDetailSheet(
          context: context,
          ref: ref,
          lang: lang,
          title: entry.title,
          summary: entry.summary,
          sectionNote: entry.reflection,
          sectionHeading: AppLocalizations.getAsmaReflectionHeading(lang),
          headerArabic: entry.arabic,
          ayahRefs: entry.ayahRefs,
          favoriteKind: ExploreFavoriteKind.asma,
          favoriteId: entry.id,
          onOpenReader: (ayahRef) {
            openReaderFromAyahRef(ref, ayahRef);
            openReaderScreen(context, ref);
          },
        );
        return;
      }
      return;
    case ExploreFavoriteKind.theme:
      final catalog = await ref.read(themeCatalogProvider.future);
      for (final entry in catalog.entries) {
        if (entry.id != favorite.id || !context.mounted) continue;
        await showExploreDetailSheet(
          context: context,
          ref: ref,
          lang: lang,
          title: entry.title,
          summary: entry.summary,
          sectionNote: entry.reflection,
          sectionHeading: AppLocalizations.getThemeReflectionHeading(lang),
          ayahRefs: entry.ayahRefs,
          favoriteKind: ExploreFavoriteKind.theme,
          favoriteId: entry.id,
          onOpenReader: (ayahRef) {
            openReaderFromAyahRef(ref, ayahRef);
            openReaderScreen(context, ref);
          },
        );
        return;
      }
      return;
  }
}

class ExploreFavoritesPage extends ConsumerWidget {
  const ExploreFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final favorites = ref.watch(exploreFavoritesProvider);
    final duas = ref.watch(duaCatalogProvider).valueOrNull?.entries ?? const [];
    final science =
        ref.watch(scienceCatalogProvider).valueOrNull?.entries ?? const [];
    final asma = ref.watch(asmaCatalogProvider).valueOrNull?.entries ?? const [];
    final themes =
        ref.watch(themeCatalogProvider).valueOrNull?.entries ?? const [];
    final views = resolveExploreFavorites(
      favorites: favorites,
      lang: lang,
      duas: duas,
      science: science,
      asma: asma,
      themes: themes,
    );

    return ExploreSectionScaffold(
      title: AppLocalizations.getExploreFavoritesTitle(lang),
      subtitle: AppLocalizations.getExploreFavoritesCount(views.length, lang),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: views.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final view = views[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
            title: Text(view.title),
            subtitle: Text(
              AppLocalizations.getExploreFavoriteKindLabel(
                view.favorite.kind.name,
                lang,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openExploreFavorite(context, ref, view.favorite),
          );
        },
      ),
    );
  }
}
