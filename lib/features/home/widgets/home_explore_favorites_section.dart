import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/explore/favorite_display.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/explore_favorites_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/dua/open_explore_favorite.dart';
import 'package:quran_offline/features/dua/widgets/favorite_item_card.dart';
import 'package:quran_offline/features/home/widgets/home_section_link.dart';

class HomeExploreFavoritesSection extends ConsumerWidget {
  const HomeExploreFavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final displays = resolveFavoriteDisplays(
      favorites: ref.watch(exploreFavoritesProvider),
      lang: lang,
      duas: ref.watch(duaCatalogProvider).valueOrNull?.entries ?? const [],
      science: ref.watch(scienceCatalogProvider).valueOrNull?.entries ?? const [],
      asma: ref.watch(asmaCatalogProvider).valueOrNull?.entries ?? const [],
      themes: ref.watch(themeCatalogProvider).valueOrNull?.entries ?? const [],
    );
    if (displays.isEmpty) return const SizedBox.shrink();

    final preview = displays.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: AppLocalizations.getHomeFavoritesSectionTitle(lang),
            linkLabel: AppLocalizations.getHomeAllFavoritesCountLink(
              displays.length,
              lang,
            ),
            onLinkPressed: () => openExploreFavoritesPage(context),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final display = preview[index];
                return SizedBox(
                  width: 236,
                  child: FavoriteItemCard(
                    display: display,
                    compact: true,
                    removeLabel: '',
                    onTap: () =>
                        openExploreFavorite(context, ref, display.favorite),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
