import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/home/widgets/home_section_link.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

const _homeKoleksiLimit = 4;

enum _KoleksiKind { bookmark, highlight }

class _KoleksiItem {
  const _KoleksiItem({
    required this.kind,
    required this.at,
    required this.surahId,
    required this.ayahNo,
    this.highlightColor,
  });

  final _KoleksiKind kind;
  final DateTime at;
  final int surahId;
  final int ayahNo;
  final int? highlightColor;
}

class HomeActivitySection extends ConsumerWidget {
  const HomeActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final highlightsAsync = ref.watch(highlightsProvider);
    final surahsAsync = ref.watch(surahNamesProvider);

    return bookmarksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (bookmarks) => highlightsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (highlights) => surahsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (surahs) {
            final feed = _buildFeed(bookmarks, highlights);
            final hasAny = feed.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeSectionHeader(
                    title: AppLocalizations.getHomeCollectionSectionTitle(lang),
                    linkLabel: AppLocalizations.getMenuText('bookmarks', lang),
                    onLinkPressed: () {
                      ref.read(librarySubTabProvider.notifier).state = 0;
                      ref.read(currentTabProvider.notifier).state = AppTab.library;
                    },
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                      ),
                      color: colorScheme.surface.withValues(alpha: 0.94),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hasAny) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 2),
                              child: Text(
                                AppLocalizations.formatHomeKoleksiStats(
                                  bookmarks: bookmarks.length,
                                  highlights: highlights.length,
                                  language: lang,
                                ),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                          if (!hasAny)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                AppLocalizations.getHomeKoleksiEmpty(lang),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.45,
                                    ),
                              ),
                            )
                          else
                            ...feed.asMap().entries.map(
                              (entry) => _KoleksiTile(
                                item: entry.value,
                                surahName: _surahName(surahs, entry.value.surahId),
                                lang: lang,
                                isLast: entry.key == feed.length - 1,
                                onTap: () => _openAyah(
                                  context,
                                  ref,
                                  entry.value.surahId,
                                  entry.value.ayahNo,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_KoleksiItem> _buildFeed(
    List<Bookmark> bookmarks,
    List<Highlight> highlights,
  ) {
    final items = <_KoleksiItem>[
      ...bookmarks.map(
        (b) => _KoleksiItem(
          kind: _KoleksiKind.bookmark,
          at: b.createdAt,
          surahId: b.surahId,
          ayahNo: b.ayahNo,
        ),
      ),
      ...highlights.map(
        (h) => _KoleksiItem(
          kind: _KoleksiKind.highlight,
          at: h.createdAt,
          surahId: h.surahId,
          ayahNo: h.ayahNo,
          highlightColor: h.color,
        ),
      ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    final seen = <String>{};
    final feed = <_KoleksiItem>[];
    for (final item in items) {
      final key = '${item.kind.name}:${item.surahId}:${item.ayahNo}';
      if (seen.add(key)) {
        feed.add(item);
      }
      if (feed.length >= _homeKoleksiLimit) break;
    }
    return feed;
  }

  String _surahName(List<SurahInfo> surahs, int surahId) {
    for (final surah in surahs) {
      if (surah.id == surahId) return surah.englishName;
    }
    return 'Surah $surahId';
  }

  void _openAyah(
    BuildContext context,
    WidgetRef ref,
    int surahId,
    int ayahNo,
  ) {
    ref.read(readerSourceProvider.notifier).state =
        SurahSource(surahId, targetAyahNo: ayahNo);
    ref.read(targetAyahProvider.notifier).state = ayahNo;
    openReaderScreen(context, ref);
  }
}

class _KoleksiTile extends StatelessWidget {
  const _KoleksiTile({
    required this.item,
    required this.surahName,
    required this.lang,
    required this.isLast,
    required this.onTap,
  });

  final _KoleksiItem item;
  final String surahName;
  final String lang;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = switch (item.kind) {
      _KoleksiKind.bookmark => colorScheme.primary,
      _KoleksiKind.highlight =>
        item.highlightColor != null
            ? highlightDisplayColor(item.highlightColor!)
            : colorScheme.secondary,
    };
    final typeLabel = switch (item.kind) {
      _KoleksiKind.bookmark => AppLocalizations.getMenuText('bookmarks', lang),
      _KoleksiKind.highlight => AppLocalizations.getMenuText('highlights', lang),
    };
    final refLabel = AppLocalizations.formatDuaAyahRef(
      item.surahId,
      item.ayahNo,
      item.ayahNo,
      lang,
    );
    final icon = switch (item.kind) {
      _KoleksiKind.bookmark => Icons.bookmark_outline_rounded,
      _KoleksiKind.highlight => Icons.highlight_outlined,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$surahName · $refLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                AppLocalizations.formatHomeRelativeTime(item.at, lang),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
