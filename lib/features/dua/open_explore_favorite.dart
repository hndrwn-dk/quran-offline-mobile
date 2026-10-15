import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:quran_offline/core/explore/favorite_display.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/explore_favorites_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_filter_chip.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/core/widgets/undoable_dismissible.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/dua/widgets/explore_section_scaffold.dart';
import 'package:quran_offline/features/dua/widgets/favorite_item_card.dart';
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

class ExploreFavoritesPage extends ConsumerStatefulWidget {
  const ExploreFavoritesPage({super.key});

  @override
  ConsumerState<ExploreFavoritesPage> createState() =>
      _ExploreFavoritesPageState();
}

class _ExploreFavoritesPageState extends ConsumerState<ExploreFavoritesPage> {
  final _searchController = TextEditingController();
  var _searchOpen = false;
  ExploreFavoriteKind? _filter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final duas = ref.watch(duaCatalogProvider).valueOrNull?.entries ?? const [];
    final science =
        ref.watch(scienceCatalogProvider).valueOrNull?.entries ?? const [];
    final asma =
        ref.watch(asmaCatalogProvider).valueOrNull?.entries ?? const [];
    final themes =
        ref.watch(themeCatalogProvider).valueOrNull?.entries ?? const [];
    final displays = resolveFavoriteDisplays(
      favorites: ref.watch(exploreFavoritesProvider),
      lang: lang,
      duas: duas,
      science: science,
      asma: asma,
      themes: themes,
    );
    final counts = <ExploreFavoriteKind, int>{};
    for (final display in displays) {
      final kind = display.favorite.kind;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    final query = _searchController.text.trim().toLowerCase();
    final visible = displays.where((display) {
      if (_filter != null && display.favorite.kind != _filter) return false;
      if (query.isEmpty) return true;
      final haystack =
          '${display.title} ${display.eyebrow} ${display.qsLabel ?? ''}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
    final showChips = counts.length > 1;
    final showSearch = displays.length >= 10;

    return ExploreSectionScaffold(
      title: AppLocalizations.getExploreFavoritesTitle(lang),
      subtitle: displays.isEmpty
          ? AppLocalizations.getExploreFavoritesEmptySubtitle(lang)
          : AppLocalizations.getExploreFavoritesCount(displays.length, lang),
      actions: [
        if (showSearch)
          IconButton(
            tooltip: AppLocalizations.getExploreFavoritesSearchHint(lang),
            onPressed: () => setState(() => _searchOpen = !_searchOpen),
            icon: const Icon(Icons.search),
          ),
      ],
      body: displays.isEmpty
          ? _FavoritesEmpty(lang: lang)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: visible.length + (showChips || _searchOpen ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (showChips || _searchOpen) {
                  if (index == 0) {
                    return _FavoritesFilters(
                      lang: lang,
                      total: displays.length,
                      counts: counts,
                      showChips: showChips,
                      selected: _filter,
                      searchOpen: _searchOpen,
                      controller: _searchController,
                      onQuery: () => setState(() {}),
                      onSelected: (kind) => setState(() => _filter = kind),
                    );
                  }
                  index -= 1;
                }
                final display = visible[index];
                return UndoableDismissible(
                  dismissKey: ValueKey(display.favorite.key),
                  backgroundLabel:
                      AppLocalizations.getExploreFavoritesSwipeDelete(lang),
                  backgroundIcon: Icons.heart_broken_outlined,
                  onDismissed: () => _remove(display.favorite, lang),
                  child: FavoriteItemCard(
                    display: display,
                    removeLabel:
                        AppLocalizations.getExploreFavoritesRemoveSemantics(
                      lang,
                    ),
                    onTap: () =>
                        openExploreFavorite(context, ref, display.favorite),
                    onRemove: () => _remove(display.favorite, lang),
                  ),
                );
              },
            ),
    );
  }

  void _remove(ExploreFavorite entry, String lang) {
    ref.read(exploreFavoritesProvider.notifier).toggle(entry.kind, entry.id);
    showUndoSnackBar(
      context,
      message: AppLocalizations.getExploreFavoritesRemoved(lang),
      actionLabel: AppLocalizations.getExploreFavoritesUndo(lang),
      onAction: () {
        ref.read(exploreFavoritesProvider.notifier).restore(entry);
      },
    );
  }
}

class _FavoritesFilters extends StatelessWidget {
  const _FavoritesFilters({
    required this.lang,
    required this.total,
    required this.counts,
    required this.showChips,
    required this.selected,
    required this.searchOpen,
    required this.controller,
    required this.onQuery,
    required this.onSelected,
  });

  final String lang;
  final int total;
  final Map<ExploreFavoriteKind, int> counts;
  final bool showChips;
  final ExploreFavoriteKind? selected;
  final bool searchOpen;
  final TextEditingController controller;
  final VoidCallback onQuery;
  final ValueChanged<ExploreFavoriteKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showChips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(null, 'all', total),
                for (final kind in ExploreFavoriteKind.values)
                  if (counts[kind] != null) ...[
                    const SizedBox(width: 8),
                    _chip(kind, kind.name, counts[kind]!),
                  ],
              ],
            ),
          ),
        if (searchOpen) ...[
          const SizedBox(height: 8),
          AppSearchField(
            controller: controller,
            hintText: AppLocalizations.getExploreFavoritesSearchHint(lang),
            autofocus: true,
            onChanged: (_) => onQuery(),
            onClear: onQuery,
          ),
        ],
      ],
    );
  }

  Widget _chip(ExploreFavoriteKind? kind, String key, int count) {
    return AppFilterChip(
      label: AppLocalizations.getExploreFavoriteFilterChip(key, count, lang),
      selected: selected == kind,
      onSelected: (_) =>
          onSelected(selected == kind && kind != null ? null : kind),
    );
  }
}

class _FavoritesEmpty extends ConsumerWidget {
  const _FavoritesEmpty({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.favorite_border,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.getExploreFavoritesEmptyTitle(lang),
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.getExploreFavoritesEmptyBody(lang),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = AppTab.explore;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(AppLocalizations.getExploreFavoritesEmptyCta(lang)),
            ),
          ],
        ),
      ),
    );
  }
}
