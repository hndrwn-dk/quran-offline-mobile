import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
                color: colorScheme.onSurface.withOpacity(0.08),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.auto_stories_outlined,
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
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: AppLocalizations.getDuaCategoryLabel('daily', lang)),
                  Tab(text: AppLocalizations.getDuaCategoryLabel('prophet', lang)),
                  Tab(text: AppLocalizations.getDuaCategoryLabel('science', lang)),
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
            _ThemeTabBody(lang: lang, colorScheme: colorScheme),
          ],
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
      return Center(child: Text(AppLocalizations.getThemeEmpty(lang)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
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
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          children: items
              .map(
                (entry) => _ThemeListTile(
                  entry: entry,
                  lang: lang,
                  colorScheme: colorScheme,
                  onTap: () => _showThemeDetail(context, ref, entry, lang),
                ),
              )
              .toList(),
        );
      },
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        onTap: onTap,
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
      return Center(child: Text(AppLocalizations.getDuaEmpty(lang)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
      return Center(child: Text(AppLocalizations.getScienceEmpty(lang)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
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
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          children: items
              .map(
                (entry) => _ScienceListTile(
                  entry: entry,
                  lang: lang,
                  colorScheme: colorScheme,
                  onTap: () => _showScienceDetail(context, ref, entry, lang),
                ),
              )
              .toList(),
        );
      },
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        onTap: onTap,
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
      return Center(child: Text(AppLocalizations.getDuaEmpty(lang)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
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
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          children: items
              .map(
                (entry) => _DuaListTile(
                  entry: entry,
                  lang: lang,
                  colorScheme: colorScheme,
                  dense: true,
                  onTap: () => _showDuaDetail(context, ref, entry, lang),
                ),
              )
              .toList(),
        );
      },
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
    return Card(
      elevation: 0,
      margin: dense ? const EdgeInsets.only(left: 8, right: 8, bottom: 4) : null,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        onTap: onTap,
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
}) {
  return showExploreDetailSheet(
    context: context,
    lang: lang,
    title: title,
    summary: summary,
    sectionNote: sectionNote,
    sectionHeading: sectionHeading,
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
