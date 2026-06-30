import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/asma_entry.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/dua/life_situation.dart';
import 'package:quran_offline/features/dua/explore_icons.dart';
import 'package:quran_offline/features/dua/explore_search.dart';
import 'package:quran_offline/features/dua/widgets/explore_hub_search_bar.dart';
import 'package:quran_offline/features/dua/widgets/explore_hub_section_card.dart';
import 'package:quran_offline/features/dua/widgets/explore_section_scaffold.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

class _CatalogLoadError extends StatelessWidget {
  const _CatalogLoadError({
    required this.message,
    required this.onRetry,
    required this.lang,
  });

  final String message;
  final VoidCallback onRetry;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(AppLocalizations.getCatalogRetry(lang)),
            ),
          ],
        ),
      ),
    );
  }
}

class DuaScreen extends ConsumerWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;
    final catalogAsync = ref.watch(duaCatalogProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: HomeBackdrop.topTint(colorScheme),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
        backgroundColor: HomeBackdrop.topTint(colorScheme),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.library_books,
                size: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.getMenuText('dua', lang),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.getSubtitleText('dua_subtitle', lang),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.getDuaLoadError(lang),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (catalog) => _ExploreHubBody(
          catalog: catalog,
          lang: lang,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

class _ExploreHubBody extends ConsumerStatefulWidget {
  const _ExploreHubBody({
    required this.catalog,
    required this.lang,
    required this.colorScheme,
  });

  final DuaCatalog catalog;
  final String lang;
  final ColorScheme colorScheme;

  @override
  ConsumerState<_ExploreHubBody> createState() => _ExploreHubBodyState();
}

class _ExploreHubBodyState extends ConsumerState<_ExploreHubBody> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  String _query = '';

  DuaCatalog get catalog => widget.catalog;
  String get lang => widget.lang;
  ColorScheme get colorScheme => widget.colorScheme;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    _searchFocusNode.unfocus();
  }

  void _openSearchHit(ExploreSearchHit hit) {
    switch (hit.kind) {
      case ExploreSearchKind.dua:
        final entry = hit.dua;
        if (entry != null) _showDuaDetail(context, ref, entry, lang);
      case ExploreSearchKind.science:
        final entry = hit.science;
        if (entry != null) _showScienceDetail(context, ref, entry, lang);
      case ExploreSearchKind.theme:
        final entry = hit.theme;
        if (entry != null) _showThemeDetail(context, ref, entry, lang);
      case ExploreSearchKind.asma:
        final entry = hit.asma;
        if (entry != null) _showAsmaDetail(context, ref, entry, lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asmaAsync = ref.watch(asmaCatalogProvider);
    final scienceAsync = ref.watch(scienceCatalogProvider);
    final themeAsync = ref.watch(themeCatalogProvider);

    final asmaCatalog = asmaAsync.value;
    final scienceCatalog = scienceAsync.value;
    final themeCatalog = themeAsync.value;

    final trimmedQuery = _query.trim();
    final isSearching = trimmedQuery.isNotEmpty;

    final searchHits = isSearching
        ? searchExploreContent(
            query: trimmedQuery,
            lang: lang,
            duaCatalog: catalog,
            asmaCatalog: asmaCatalog,
            scienceCatalog: scienceCatalog,
            themeCatalog: themeCatalog,
          )
        : const <ExploreSearchHit>[];

    final dailyCount = catalog.byCategory('daily').length;
    final prophetGrouped = catalog.prophetsGrouped();
    final prophetCount =
        prophetGrouped.values.fold<int>(0, (sum, list) => sum + list.length);
    final scienceCount = scienceCatalog?.entries.length ?? 0;
    final asmaCount = asmaCatalog?.entries.length ?? 0;
    final themeCount = themeCatalog?.entries.length ?? 0;

    final sections = [
      _HubSection(
        sectionKey: 'prophet',
        countLabel: AppLocalizations.getDuaProphetCount(prophetCount, lang),
        onTap: () => _openProphetHub(context, lang, colorScheme, prophetGrouped),
      ),
      _HubSection(
        sectionKey: 'science',
        countLabel: AppLocalizations.getScienceTopicCount(scienceCount, lang),
        onTap: () => _openScienceHub(context, lang, colorScheme),
      ),
      _HubSection(
        sectionKey: 'asma',
        countLabel: AppLocalizations.getAsmaNamesCount(asmaCount, lang),
        onTap: () => _openAsmaSection(context, lang, colorScheme),
      ),
      _HubSection(
        sectionKey: 'life_theme',
        countLabel: AppLocalizations.getLifeSituationHubCount(
          dailyCount,
          themeCount,
          lang,
        ),
        onTap: () => _openThemeHub(context, lang, colorScheme),
      ),
    ];

    return HomeBackdrop(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppSearchFieldInset(
              padding: const EdgeInsets.fromLTRB(
                kAppContentHorizontalInset,
                kAppBodyTopInset,
                kAppContentHorizontalInset,
                12,
              ),
              child: ExploreHubSearchBar(
                lang: lang,
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
          ),
          if (!isSearching) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                kAppContentHorizontalInset,
                0,
                kAppContentHorizontalInset,
                24,
              ),
              sliver: SliverList.separated(
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return ExploreHubSectionCard(
                    sectionKey: section.sectionKey,
                    title:
                        AppLocalizations.getDuaCategoryLabel(section.sectionKey, lang),
                    countLabel: section.countLabel,
                    hint: AppLocalizations.getExploreHubHint(section.sectionKey, lang),
                    onTap: section.onTap,
                  );
                },
              ),
            ),
          ] else if (searchHits.isEmpty) ...[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppLocalizations.getExploreSearchEmpty(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                kAppContentHorizontalInset,
                0,
                kAppContentHorizontalInset,
                24,
              ),
              sliver: SliverList.separated(
                itemCount: searchHits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final hit = searchHits[index];
                  return ExploreTopicCard(
                    title: hit.title,
                    refLabel: hit.subtitle,
                    onTap: () => _openSearchHit(hit),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openProphetHub(
    BuildContext context,
    String lang,
    ColorScheme colorScheme,
    Map<String, List<DuaEntry>> grouped,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSectionScaffold(
          title: AppLocalizations.getDuaCategoryLabel('prophet', lang),
          subtitle: AppLocalizations.getExploreHubHint('prophet', lang),
          body: _ProphetCategoryGrid(
            grouped: grouped,
            lang: lang,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }

  void _openScienceHub(
    BuildContext context,
    String lang,
    ColorScheme colorScheme,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSectionScaffold(
          title: AppLocalizations.getDuaCategoryLabel('science', lang),
          subtitle: AppLocalizations.getExploreHubHint('science', lang),
          body: _ScienceTabBody(lang: lang, colorScheme: colorScheme),
        ),
      ),
    );
  }

  void _openAsmaSection(
    BuildContext context,
    String lang,
    ColorScheme colorScheme,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSectionScaffold(
          title: AppLocalizations.getDuaCategoryLabel('asma', lang),
          subtitle: AppLocalizations.getExploreHubHint('asma', lang),
          body: _AsmaTabBody(lang: lang, colorScheme: colorScheme),
        ),
      ),
    );
  }

  void _openThemeHub(
    BuildContext context,
    String lang,
    ColorScheme colorScheme,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSectionScaffold(
          title: AppLocalizations.getDuaCategoryLabel('life_theme', lang),
          subtitle: AppLocalizations.getExploreHubHint('life_theme', lang),
          body: _ThemeTabBody(lang: lang, colorScheme: colorScheme),
        ),
      ),
    );
  }
}

class _HubSection {
  const _HubSection({
    required this.sectionKey,
    required this.countLabel,
    required this.onTap,
  });

  final String sectionKey;
  final String countLabel;
  final VoidCallback onTap;
}

class _AsmaTabBody extends ConsumerWidget {
  const _AsmaTabBody({
    required this.lang,
    required this.colorScheme,
  });

  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asmaAsync = ref.watch(asmaCatalogProvider);
    return asmaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _CatalogLoadError(
        message: AppLocalizations.getAsmaLoadError(lang),
        onRetry: () => ref.invalidate(asmaCatalogProvider),
        lang: lang,
      ),
      data: (catalog) => _AsmaListView(
        entries: catalog.sorted(),
        lang: lang,
        colorScheme: colorScheme,
      ),
    );
  }
}

class _AsmaListView extends ConsumerWidget {
  const _AsmaListView({
    required this.entries,
    required this.lang,
    required this.colorScheme,
  });

  final List<AsmaEntry> entries;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return _ExploreTabScrollView.emptyMessage(
        AppLocalizations.getAsmaEmpty(lang),
      );
    }
    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _AsmaListTile(
                entry: entry,
                lang: lang,
                colorScheme: colorScheme,
                onTap: () => _showAsmaDetail(context, ref, entry, lang),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AsmaListTile extends StatelessWidget {
  const _AsmaListTile({
    required this.entry,
    required this.lang,
    required this.colorScheme,
    required this.onTap,
  });

  final AsmaEntry entry;
  final String lang;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final refLabel = entry.ayahRefs.length == 1
        ? AppLocalizations.formatDuaAyahRef(
            entry.primaryRef.surah,
            entry.primaryRef.from,
            entry.primaryRef.to,
            lang,
          )
        : AppLocalizations.formatThemeAyahLabel(entry.ayahRefs.length, lang);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${entry.number}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.transliteration,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.title.forLanguage(lang),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        refLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      entry.arabic,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'UthmanicHafsV22',
                            fontFamilyFallback: const ['UthmanicHafs'],
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LifeSituationTabBody extends ConsumerWidget {
  const _LifeSituationTabBody({
    required this.lang,
    required this.colorScheme,
  });

  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duaAsync = ref.watch(duaCatalogProvider);
    final themeAsync = ref.watch(themeCatalogProvider);

    if (duaAsync.isLoading || themeAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (duaAsync.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.getDuaLoadError(lang),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (themeAsync.hasError) {
      return _CatalogLoadError(
        message: AppLocalizations.getThemeLoadError(lang),
        onRetry: () => ref.invalidate(themeCatalogProvider),
        lang: lang,
      );
    }

    final duaCatalog = duaAsync.requireValue;
    final themeCatalog = themeAsync.requireValue;
    final buckets = buildLifeSituationBuckets(
      duaCatalog: duaCatalog,
      themeCatalog: themeCatalog,
    );

    if (buckets.isEmpty) {
      return _ExploreTabScrollView.emptyMessage(
        AppLocalizations.getThemeEmpty(lang),
      );
    }

    return _LifeSituationCategoryGrid(
      buckets: buckets,
      lang: lang,
      colorScheme: colorScheme,
    );
  }
}

class _LifeSituationCategoryGrid extends ConsumerWidget {
  const _LifeSituationCategoryGrid({
    required this.buckets,
    required this.lang,
    required this.colorScheme,
  });

  final List<LifeSituationBucket> buckets;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderedBuckets = <LifeSituationBucket>[];
    LifeSituationBucket? featured;
    for (final bucket in buckets) {
      if (bucket.categoryKey == kLifeThemeFeaturedCategoryKey) {
        featured = bucket;
      } else {
        orderedBuckets.add(bucket);
      }
    }
    if (featured != null) {
      orderedBuckets.insert(0, featured);
    }

    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: orderedBuckets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final bucket = orderedBuckets[index];
              final categoryKey = bucket.categoryKey;
              final countLabel = AppLocalizations.getLifeSituationCategorySubtitle(
                bucket.duas.length,
                bucket.reflections.length,
                lang,
              );
              if (categoryKey == kLifeThemeFeaturedCategoryKey) {
                return ExploreFeaturedCategoryCard(
                  assetPath: ExploreIcons.themeCategoryAsset(categoryKey),
                  icon: ExploreIcons.themeCategory(categoryKey),
                  title: AppLocalizations.getThemeCategoryLabel(
                    categoryKey,
                    lang,
                  ),
                  countLabel: countLabel,
                  hint: AppLocalizations.getLifeThemeFeaturedCategoryHint(lang),
                  featuredLabel: AppLocalizations.getExploreFeaturedBadge(lang),
                  onTap: () => _openLifeSituationCategory(
                    context,
                    bucket,
                    lang,
                    colorScheme,
                  ),
                );
              }
              return ExploreCategoryCard(
                assetPath: ExploreIcons.themeCategoryAsset(categoryKey),
                icon: ExploreIcons.themeCategory(categoryKey),
                title: AppLocalizations.getThemeCategoryLabel(
                  categoryKey,
                  lang,
                ),
                subtitle: countLabel,
                onTap: () => _openLifeSituationCategory(
                  context,
                  bucket,
                  lang,
                  colorScheme,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openLifeSituationCategory(
    BuildContext context,
    LifeSituationBucket bucket,
    String lang,
    ColorScheme colorScheme,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSectionScaffold(
          title: AppLocalizations.getThemeCategoryLabel(
            bucket.categoryKey,
            lang,
          ),
          subtitle: AppLocalizations.getLifeSituationCategorySubtitle(
            bucket.duas.length,
            bucket.reflections.length,
            lang,
          ),
          parentSection: AppLocalizations.getDuaCategoryLabel('life_theme', lang),
          body: _LifeSituationCategoryBody(
            bucket: bucket,
            lang: lang,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

class _LifeSituationCategoryBody extends ConsumerWidget {
  const _LifeSituationCategoryBody({
    required this.bucket,
    required this.lang,
    required this.colorScheme,
  });

  final LifeSituationBucket bucket;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slivers = <Widget>[];

    if (bucket.duas.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: _LifeSituationSectionHeader(
            title: AppLocalizations.getLifeSituationSectionDua(
              bucket.duas.length,
              lang,
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverList.separated(
            itemCount: bucket.duas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = bucket.duas[index];
              final ayahRef = entry.primaryRef;
              final refLabel = entry.ayahRefs.length == 1
                  ? AppLocalizations.formatDuaAyahRef(
                      ayahRef.surah,
                      ayahRef.from,
                      ayahRef.to,
                      lang,
                    )
                  : AppLocalizations.formatThemeAyahLabel(
                      entry.ayahRefs.length,
                      lang,
                    );
              return ExploreTopicCard(
                title: entry.title.forLanguage(lang),
                refLabel: refLabel,
                onTap: () => _showDuaDetail(context, ref, entry, lang),
              );
            },
          ),
        ),
      );
    }

    if (bucket.reflections.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: _LifeSituationSectionHeader(
            title: AppLocalizations.getLifeSituationSectionReflection(
              bucket.reflections.length,
              lang,
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: bucket.reflections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = bucket.reflections[index];
              final ayahRef = entry.primaryRef;
              final refLabel = entry.ayahRefs.length == 1
                  ? AppLocalizations.formatDuaAyahRef(
                      ayahRef.surah,
                      ayahRef.from,
                      ayahRef.to,
                      lang,
                    )
                  : AppLocalizations.formatThemeAyahLabel(
                      entry.ayahCount,
                      lang,
                    );
              return ExploreTopicCard(
                title: entry.title.forLanguage(lang),
                refLabel: refLabel,
                onTap: () => _showThemeDetail(context, ref, entry, lang),
              );
            },
          ),
        ),
      );
    }

    return _ExploreTabScrollView(lang: lang, slivers: slivers);
  }
}

class _LifeSituationSectionHeader extends StatelessWidget {
  const _LifeSituationSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ThemeTabBody extends ConsumerWidget {
  const _ThemeTabBody({
    required this.lang,
    required this.colorScheme,
  });

  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LifeSituationTabBody(lang: lang, colorScheme: colorScheme);
  }
}

class _ScienceTabBody extends ConsumerWidget {
  const _ScienceTabBody({
    required this.lang,
    required this.colorScheme,
  });

  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scienceAsync = ref.watch(scienceCatalogProvider);
    return scienceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _CatalogLoadError(
        message: AppLocalizations.getScienceLoadError(lang),
        onRetry: () => ref.invalidate(scienceCatalogProvider),
        lang: lang,
      ),
      data: (catalog) => _ScienceCategoryGrid(
        grouped: catalog.groupedByCategory(),
        lang: lang,
        colorScheme: colorScheme,
      ),
    );
  }
}

/// Blocks vertical drag when content fits one screen; no setState toggling.
class _ExploreOverflowScrollPhysics extends ClampingScrollPhysics {
  const _ExploreOverflowScrollPhysics({super.parent});

  @override
  _ExploreOverflowScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ExploreOverflowScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (position.maxScrollExtent <= 0) return false;
    return super.shouldAcceptUserOffset(position);
  }
}

class _ExploreTabScrollView extends StatefulWidget {
  const _ExploreTabScrollView({
    required this.slivers,
    required this.lang,
  });

  final List<Widget> slivers;
  final String lang;

  factory _ExploreTabScrollView.emptyMessage(String message) {
    return _ExploreTabScrollView(
      lang: 'en',
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(message)),
        ),
      ],
    );
  }

  @override
  State<_ExploreTabScrollView> createState() => _ExploreTabScrollViewState();
}

class _ExploreTabScrollViewState extends State<_ExploreTabScrollView> {
  final ScrollController _controller = ScrollController();
  bool _canScroll = false;
  bool _atBottom = true;
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollState());
  }

  @override
  void didUpdateWidget(covariant _ExploreTabScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollState());
  }

  @override
  void dispose() {
    _controller.removeListener(_syncScrollState);
    _controller.dispose();
    super.dispose();
  }

  void _syncScrollState() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final canScroll = pos.maxScrollExtent > 1;
    final atBottom = !canScroll || pos.pixels >= pos.maxScrollExtent - 12;
    final hasScrolled = pos.pixels > 4;
    if (canScroll == _canScroll &&
        atBottom == _atBottom &&
        hasScrolled == _hasScrolled) {
      return;
    }
    setState(() {
      _canScroll = canScroll;
      _atBottom = atBottom;
      _hasScrolled = hasScrolled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showFade = _canScroll && !_atBottom;
    final showHint = showFade && !_hasScrolled;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollMetricsNotification) {
          _syncScrollState();
        }
        return false;
      },
      child: Stack(
        children: [
          CustomScrollView(
            controller: _controller,
            physics: _canScroll
                ? const _ExploreOverflowScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            slivers: widget.slivers,
          ),
          if (showFade)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withValues(alpha: 0),
                        colorScheme.surface.withValues(alpha: 0.94),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showHint)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.expand_more,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.getExploreScrollHint(widget.lang),
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DuaListView extends ConsumerWidget {
  const _DuaListView({
    required this.entries,
    required this.lang,
    required this.colorScheme,
  });

  final List<DuaEntry> entries;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return _ExploreTabScrollView.emptyMessage(
        AppLocalizations.getDuaEmpty(lang),
      );
    }
    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final ayahRef = entry.primaryRef;
              final refLabel = AppLocalizations.formatDuaAyahRef(
                ayahRef.surah,
                ayahRef.from,
                ayahRef.to,
                lang,
              );
              return ExploreTopicCard(
                title: entry.title.forLanguage(lang),
                refLabel: refLabel,
                onTap: () => _showDuaDetail(context, ref, entry, lang),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScienceCategoryGrid extends ConsumerWidget {
  const _ScienceCategoryGrid({
    required this.grouped,
    required this.lang,
    required this.colorScheme,
  });

  final Map<String, List<ScienceEntry>> grouped;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (grouped.isEmpty) {
      return _ExploreTabScrollView.emptyMessage(
        AppLocalizations.getScienceEmpty(lang),
      );
    }
    final keys = grouped.keys.toList();
    final orderedKeys = <String>[];
    if (grouped.containsKey(kScienceFeaturedCategoryKey)) {
      orderedKeys.add(kScienceFeaturedCategoryKey);
    }
    for (final key in keys) {
      if (key != kScienceFeaturedCategoryKey) {
        orderedKeys.add(key);
      }
    }

    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: orderedKeys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final categoryKey = orderedKeys[index];
              final items = grouped[categoryKey]!;
              if (categoryKey == kScienceFeaturedCategoryKey) {
                return ExploreFeaturedCategoryCard(
                  icon: ExploreIcons.scienceCategory(categoryKey),
                  title: AppLocalizations.getScienceCategoryLabel(
                    categoryKey,
                    lang,
                  ),
                  countLabel: AppLocalizations.getScienceTopicCount(
                    items.length,
                    lang,
                  ),
                  hint: AppLocalizations.getScienceFeaturedCategoryHint(lang),
                  featuredLabel: AppLocalizations.getExploreFeaturedBadge(lang),
                  onTap: () => _openScienceTopics(
                    context,
                    categoryKey,
                    items,
                    lang,
                    colorScheme,
                  ),
                );
              }
              return ExploreCategoryCard(
                icon: ExploreIcons.scienceCategory(categoryKey),
                title: AppLocalizations.getScienceCategoryLabel(categoryKey, lang),
                subtitle: AppLocalizations.getScienceTopicCount(items.length, lang),
                onTap: () => _openScienceTopics(
                  context,
                  categoryKey,
                  items,
                  lang,
                  colorScheme,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openScienceTopics(
    BuildContext context,
    String categoryKey,
    List<ScienceEntry> items,
    String lang,
    ColorScheme colorScheme,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSectionScaffold(
          title: AppLocalizations.getScienceCategoryLabel(categoryKey, lang),
          subtitle: AppLocalizations.getScienceTopicCount(items.length, lang),
          parentSection: AppLocalizations.getDuaCategoryLabel('science', lang),
          body: _ScienceTopicListView(
            entries: items,
            lang: lang,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

class _ScienceTopicListView extends ConsumerWidget {
  const _ScienceTopicListView({
    required this.entries,
    required this.lang,
    required this.colorScheme,
  });

  final List<ScienceEntry> entries;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final ayahRef = entry.primaryRef;
              final refLabel = AppLocalizations.formatDuaAyahRef(
                ayahRef.surah,
                ayahRef.from,
                ayahRef.to,
                lang,
              );
              return ExploreTopicCard(
                title: entry.title.forLanguage(lang),
                refLabel: refLabel,
                onTap: () => _showScienceDetail(context, ref, entry, lang),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProphetCategoryGrid extends ConsumerWidget {
  const _ProphetCategoryGrid({
    required this.grouped,
    required this.lang,
    required this.colorScheme,
  });

  final Map<String, List<DuaEntry>> grouped;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (grouped.isEmpty) {
      return _ExploreTabScrollView.emptyMessage(
        AppLocalizations.getDuaEmpty(lang),
      );
    }
    final keys = grouped.keys.toList();
    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final prophetKey = keys[index];
              final items = grouped[prophetKey]!;
              return ExploreCategoryCard(
                assetPath: ExploreIcons.prophetAsset(prophetKey),
                icon: ExploreIcons.prophet(prophetKey),
                title: AppLocalizations.getDuaProphetName(prophetKey, lang),
                subtitle: AppLocalizations.getDuaProphetCount(items.length, lang),
                onTap: () => _openProphetDuas(
                  context,
                  prophetKey,
                  items,
                  lang,
                  colorScheme,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openProphetDuas(
    BuildContext context,
    String prophetKey,
    List<DuaEntry> items,
    String lang,
    ColorScheme colorScheme,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSectionScaffold(
          title: AppLocalizations.getDuaProphetName(prophetKey, lang),
          subtitle: AppLocalizations.getDuaProphetCount(items.length, lang),
          parentSection: AppLocalizations.getDuaCategoryLabel('prophet', lang),
          body: _DuaListView(
            entries: items,
            lang: lang,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

Future<void> _showDuaDetail(
  BuildContext context,
  WidgetRef ref,
  DuaEntry entry,
  String lang,
) {
  return _showExploreDetail(
    context: context,
    ref: ref,
    lang: lang,
    title: entry.title,
    summary: entry.summary,
    ayahRefs: entry.ayahRefs,
    onOpenReader: () {
      _openInReader(ref, entry);
      openReaderScreen(context, ref);
    },
  );
}

Future<void> _showScienceDetail(
  BuildContext context,
  WidgetRef ref,
  ScienceEntry entry,
  String lang,
) {
  return _showExploreDetail(
    context: context,
    ref: ref,
    lang: lang,
    title: entry.title,
    summary: entry.summary,
    sectionNote: entry.scienceNote,
    sectionHeading: AppLocalizations.getScienceNoteHeading(lang),
    ayahRefs: entry.ayahRefs,
    onOpenReader: () {
      _openInReaderScience(ref, entry);
      openReaderScreen(context, ref);
    },
  );
}

Future<void> _showAsmaDetail(
  BuildContext context,
  WidgetRef ref,
  AsmaEntry entry,
  String lang,
) {
  return _showExploreDetail(
    context: context,
    ref: ref,
    lang: lang,
    title: entry.title,
    summary: entry.summary,
    sectionNote: entry.reflection,
    sectionHeading: AppLocalizations.getAsmaReflectionHeading(lang),
    headerArabic: entry.arabic,
    ayahRefs: entry.ayahRefs,
    onOpenReader: () {
      _openInReaderAsma(ref, entry);
      openReaderScreen(context, ref);
    },
  );
}

Future<void> _showThemeDetail(
  BuildContext context,
  WidgetRef ref,
  ThemeEntry entry,
  String lang,
) {
  return _showExploreDetail(
    context: context,
    ref: ref,
    lang: lang,
    title: entry.title,
    summary: entry.summary,
    sectionNote: entry.reflection,
    sectionHeading: AppLocalizations.getThemeReflectionHeading(lang),
    ayahRefs: entry.ayahRefs,
    onOpenReader: () {
      _openInReaderTheme(ref, entry);
      openReaderScreen(context, ref);
    },
  );
}

Future<void> _showExploreDetail({
  required BuildContext context,
  required WidgetRef ref,
  required String lang,
  required LocalizedText title,
  required LocalizedText summary,
  required List<DuaAyahRef> ayahRefs,
  required VoidCallback onOpenReader,
  LocalizedText? sectionNote,
  String? sectionHeading,
  String? headerArabic,
}) {
  return showExploreDetailSheet(
    context: context,
    ref: ref,
    lang: lang,
    title: title,
    summary: summary,
    sectionNote: sectionNote,
    sectionHeading: sectionHeading,
    headerArabic: headerArabic,
    ayahRefs: ayahRefs,
    onOpenReader: onOpenReader,
  );
}

void _openInReader(WidgetRef ref, DuaEntry entry) {
  openReaderFromAyahRefs(ref, [entry.primaryRef]);
}

void _openInReaderScience(WidgetRef ref, ScienceEntry entry) {
  openReaderFromAyahRefs(ref, entry.ayahRefs);
}

void _openInReaderTheme(WidgetRef ref, ThemeEntry entry) {
  openReaderFromAyahRefs(ref, entry.ayahRefs);
}

void _openInReaderAsma(WidgetRef ref, AsmaEntry entry) {
  openReaderFromAyahRefs(ref, entry.ayahRefs);
}
