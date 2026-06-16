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
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
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

class DuaScreen extends ConsumerStatefulWidget {
  const DuaScreen({super.key});

  @override
  ConsumerState<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends ConsumerState<DuaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(asmaCatalogProvider.future);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;
    final catalogAsync = ref.watch(duaCatalogProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
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
          preferredSize: const Size.fromHeight(49),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: AppLocalizations.getDuaCategoryLabel('daily', lang)),
                  Tab(text: AppLocalizations.getDuaCategoryLabel('prophet', lang)),
                  Tab(text: AppLocalizations.getDuaCategoryLabel('science', lang)),
                  Tab(text: AppLocalizations.getDuaCategoryLabel('asma', lang)),
                  Tab(text: AppLocalizations.getDuaCategoryLabel('life_theme', lang)),
                ],
              ),
            ],
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
        data: (catalog) => TabBarView(
          controller: _tabController,
          children: [
            _DuaListView(
              entries: catalog.byCategory('daily'),
              lang: lang,
              colorScheme: colorScheme,
            ),
            _ProphetDuaListView(
              grouped: catalog.prophetsGrouped(),
              lang: lang,
              colorScheme: colorScheme,
            ),
            _ScienceTabBody(lang: lang, colorScheme: colorScheme),
            _AsmaTabBody(lang: lang, colorScheme: colorScheme),
            _ThemeTabBody(lang: lang, colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }
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
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
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

class _ThemeTabBody extends ConsumerWidget {
  const _ThemeTabBody({
    required this.lang,
    required this.colorScheme,
  });

  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeCatalogProvider);
    return themeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _CatalogLoadError(
        message: AppLocalizations.getThemeLoadError(lang),
        onRetry: () => ref.invalidate(themeCatalogProvider),
        lang: lang,
      ),
      data: (catalog) => _ThemeCategoryListView(
        grouped: catalog.groupedByCategory(),
        lang: lang,
        colorScheme: colorScheme,
      ),
    );
  }
}

class _ThemeCategoryListView extends ConsumerWidget {
  const _ThemeCategoryListView({
    required this.grouped,
    required this.lang,
    required this.colorScheme,
  });

  final Map<String, List<ThemeEntry>> grouped;
  final String lang;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (grouped.isEmpty) {
      return _ExploreTabScrollView.emptyMessage(
        AppLocalizations.getThemeEmpty(lang),
      );
    }
    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final categoryKey = grouped.keys.elementAt(index);
                final items = grouped[categoryKey]!;
                return ExpansionTile(
                  title: Text(
                    AppLocalizations.getThemeCategoryLabel(categoryKey, lang),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    AppLocalizations.getThemeTopicCount(items.length, lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  children: items
                      .map(
                        (entry) => _ThemeListTile(
                          entry: entry,
                          lang: lang,
                          colorScheme: colorScheme,
                          onTap: () =>
                              _showThemeDetail(context, ref, entry, lang),
                        ),
                      )
                      .toList(),
                );
              },
              childCount: grouped.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeListTile extends StatelessWidget {
  const _ThemeListTile({
    required this.entry,
    required this.lang,
    required this.colorScheme,
    required this.onTap,
  });

  final ThemeEntry entry;
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
        : AppLocalizations.formatThemeAyahLabel(entry.ayahCount, lang);
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                entry.title.forLanguage(lang),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                refLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
    );
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
      data: (catalog) => _ScienceCategoryListView(
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
              return _DuaListTile(
                entry: entry,
                lang: lang,
                colorScheme: colorScheme,
                onTap: () => _showDuaDetail(context, ref, entry, lang),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScienceCategoryListView extends ConsumerWidget {
  const _ScienceCategoryListView({
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
    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final categoryKey = grouped.keys.elementAt(index);
                final items = grouped[categoryKey]!;
                return ExpansionTile(
                  title: Text(
                    AppLocalizations.getScienceCategoryLabel(categoryKey, lang),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    AppLocalizations.getScienceTopicCount(items.length, lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  children: items
                      .map(
                        (entry) => _ScienceListTile(
                          entry: entry,
                          lang: lang,
                          colorScheme: colorScheme,
                          onTap: () =>
                              _showScienceDetail(context, ref, entry, lang),
                        ),
                      )
                      .toList(),
                );
              },
              childCount: grouped.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScienceListTile extends StatelessWidget {
  const _ScienceListTile({
    required this.entry,
    required this.lang,
    required this.colorScheme,
    required this.onTap,
  });

  final ScienceEntry entry;
  final String lang;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ref = entry.primaryRef;
    final refLabel = AppLocalizations.formatDuaAyahRef(
      ref.surah,
      ref.from,
      ref.to,
      lang,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                entry.title.forLanguage(lang),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                refLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProphetDuaListView extends ConsumerWidget {
  const _ProphetDuaListView({
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
    return _ExploreTabScrollView(
      lang: lang,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final prophetKey = grouped.keys.elementAt(index);
                final items = grouped[prophetKey]!;
                return ExpansionTile(
                  title: Text(
                    AppLocalizations.getDuaProphetName(prophetKey, lang),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    AppLocalizations.getDuaProphetCount(items.length, lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  children: items
                      .map(
                        (entry) => _DuaListTile(
                          entry: entry,
                          lang: lang,
                          colorScheme: colorScheme,
                          dense: true,
                          onTap: () =>
                              _showDuaDetail(context, ref, entry, lang),
                        ),
                      )
                      .toList(),
                );
              },
              childCount: grouped.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _DuaListTile extends StatelessWidget {
  const _DuaListTile({
    required this.entry,
    required this.lang,
    required this.colorScheme,
    required this.onTap,
    this.dense = false,
  });

  final DuaEntry entry;
  final String lang;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ref = entry.primaryRef;
    final refLabel = AppLocalizations.formatDuaAyahRef(
      ref.surah,
      ref.from,
      ref.to,
      lang,
    );
    return Padding(
      padding: dense ? const EdgeInsets.only(left: 8, right: 8, bottom: 4) : EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: dense,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: dense ? 4 : 8,
              ),
              title: Text(
                entry.title.forLanguage(lang),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                refLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
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
