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
import 'package:quran_offline/features/dua/open_explore_favorite.dart';
import 'package:quran_offline/features/home/widgets/home_section_link.dart';

class HomeExploreFavoritesSection extends ConsumerWidget {
  const HomeExploreFavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final views = resolveExploreFavorites(
      favorites: ref.watch(exploreFavoritesProvider),
      lang: lang,
      duas: ref.watch(duaCatalogProvider).valueOrNull?.entries ?? const [],
      science: ref.watch(scienceCatalogProvider).valueOrNull?.entries ?? const [],
      asma: ref.watch(asmaCatalogProvider).valueOrNull?.entries ?? const [],
      themes: ref.watch(themeCatalogProvider).valueOrNull?.entries ?? const [],
    );
    if (views.isEmpty) return const SizedBox.shrink();

    final latest = views.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: AppLocalizations.getExploreFavoritesTitle(lang),
            linkLabel: AppLocalizations.getHomeAllFavoritesLink(lang),
            onLinkPressed: () => openExploreFavoritesPage(context),
          ),
          const SizedBox(height: 8),
          Material(
            color: colorScheme.surface.withValues(alpha: 0.94),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: ListTile(
              title: Text(latest.title),
              subtitle: Text(
                AppLocalizations.getExploreFavoriteKindLabel(
                  latest.favorite.kind.name,
                  lang,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openExploreFavorite(context, ref, latest.favorite),
            ),
          ),
        ],
      ),
    );
  }
}
