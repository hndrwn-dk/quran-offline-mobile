import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/home/widgets/home_section_link.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

/// Most recent items shown on Home, across notes, bookmarks and highlights.
const int kHomeCollectionLimit = 4;

/// The parts of the Koleksi screen in its tab order (penanda, catatan,
/// sorotan); Home lists the count chips in this order too.
enum HomeCollectionKind {
  bookmark(0),
  note(1),
  highlight(2);

  const HomeCollectionKind(this.libraryTab);

  /// Index of this part in the Koleksi screen's segment tabs.
  final int libraryTab;
}

@immutable
class HomeCollectionItem {
  const HomeCollectionItem({
    required this.kind,
    required this.at,
    required this.surahId,
    required this.ayahNo,
    this.noteText,
    this.highlightColor,
  });

  final HomeCollectionKind kind;
  final DateTime at;
  final int surahId;
  final int ayahNo;
  final String? noteText;
  final int? highlightColor;
}

/// Newest first across all three types, one row per type and ayah.
List<HomeCollectionItem> buildHomeCollectionFeed({
  required List<Note> notes,
  required List<Bookmark> bookmarks,
  required List<Highlight> highlights,
  int limit = kHomeCollectionLimit,
}) {
  final items = <HomeCollectionItem>[
    for (final n in notes)
      HomeCollectionItem(
        kind: HomeCollectionKind.note,
        at: n.updatedAt,
        surahId: n.surahId,
        ayahNo: n.ayahNo,
        noteText: n.note,
      ),
    for (final b in bookmarks)
      HomeCollectionItem(
        kind: HomeCollectionKind.bookmark,
        at: b.createdAt,
        surahId: b.surahId,
        ayahNo: b.ayahNo,
      ),
    for (final h in highlights)
      HomeCollectionItem(
        kind: HomeCollectionKind.highlight,
        at: h.createdAt,
        surahId: h.surahId,
        ayahNo: h.ayahNo,
        highlightColor: h.color,
      ),
  ]..sort((a, b) => b.at.compareTo(a.at));

  final seen = <String>{};
  final feed = <HomeCollectionItem>[];
  for (final item in items) {
    if (!seen.add('${item.kind.name}:${item.surahId}:${item.ayahNo}')) {
      continue;
    }
    feed.add(item);
    if (feed.length >= limit) break;
  }
  return feed;
}

/// Home "KOLEKSI": mirrors the Koleksi screen (catatan, penanda, sorotan) with
/// count chips that open each part and the most recent items of every type.
class HomeCollectionSection extends ConsumerWidget {
  const HomeCollectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final notes = ref.watch(notesProvider).valueOrNull;
    final bookmarks = ref.watch(bookmarksProvider).valueOrNull;
    final highlights = ref.watch(highlightsProvider).valueOrNull;
    final surahs = ref.watch(surahNamesProvider).valueOrNull;
    if (notes == null ||
        bookmarks == null ||
        highlights == null ||
        surahs == null) {
      return const SizedBox.shrink();
    }

    final feed = buildHomeCollectionFeed(
      notes: notes,
      bookmarks: bookmarks,
      highlights: highlights,
    );
    final counts = {
      HomeCollectionKind.note: notes.length,
      HomeCollectionKind.bookmark: bookmarks.length,
      HomeCollectionKind.highlight: highlights.length,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: AppLocalizations.getHomeCollectionSectionTitle(lang),
            linkLabel: AppLocalizations.getHomeSeeAllLink(lang),
            onLinkPressed: () => _openLibrary(ref),
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
              child: feed.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        AppLocalizations.getHomeCollectionEmpty(lang),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final kind in HomeCollectionKind.values)
                                if (counts[kind]! > 0)
                                  _CountChip(
                                    key: Key(
                                        'home_collection_chip_${kind.name}'),
                                    kind: kind,
                                    label: AppLocalizations
                                        .formatHomeCollectionCount(
                                      kind.name,
                                      counts[kind]!,
                                      lang,
                                    ),
                                    onTap: () => _openLibrary(ref, kind),
                                  ),
                            ],
                          ),
                        ),
                        for (var i = 0; i < feed.length; i++)
                          _CollectionRow(
                            key: Key('home_collection_row_$i'),
                            item: feed[i],
                            surahName: _surahName(surahs, feed[i].surahId),
                            lang: lang,
                            isLast: i == feed.length - 1,
                            onTap: () => _openAyah(
                              context,
                              ref,
                              feed[i].surahId,
                              feed[i].ayahNo,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _surahName(List<SurahInfo> surahs, int surahId) {
    for (final surah in surahs) {
      if (surah.id == surahId) return surah.englishName;
    }
    return 'Surah $surahId';
  }

  /// Koleksi screen, on [kind]'s part when given.
  static void _openLibrary(WidgetRef ref, [HomeCollectionKind? kind]) {
    if (kind != null) {
      ref.read(librarySubTabProvider.notifier).state = kind.libraryTab;
    }
    ref.read(currentTabProvider.notifier).state = AppTab.library;
  }

  static void _openAyah(
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

IconData _iconFor(HomeCollectionKind kind) => switch (kind) {
      HomeCollectionKind.note => Icons.sticky_note_2_outlined,
      HomeCollectionKind.bookmark => Icons.bookmark_outline_rounded,
      HomeCollectionKind.highlight => Icons.border_color_outlined,
    };

class _CountChip extends StatelessWidget {
  const _CountChip({
    super.key,
    required this.kind,
    required this.label,
    required this.onTap,
  });

  final HomeCollectionKind kind;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(kind), size: 15, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    super.key,
    required this.item,
    required this.surahName,
    required this.lang,
    required this.isLast,
    required this.onTap,
  });

  final HomeCollectionItem item;
  final String surahName;
  final String lang;
  final bool isLast;
  final VoidCallback onTap;

  static String? _snippet(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = switch (item.kind) {
      HomeCollectionKind.highlight => item.highlightColor != null
          ? highlightDisplayColor(item.highlightColor!)
          : colorScheme.secondary,
      _ => colorScheme.primary,
    };
    final refLabel = AppLocalizations.formatDuaAyahRef(
      item.surahId,
      item.ayahNo,
      item.ayahNo,
      lang,
    );
    final noteSnippet =
        item.kind == HomeCollectionKind.note ? _snippet(item.noteText) : null;
    final subtitle = switch (item.kind) {
      HomeCollectionKind.note =>
        noteSnippet ?? AppLocalizations.getMenuText('notes', lang),
      HomeCollectionKind.bookmark =>
        AppLocalizations.getMenuText('bookmarks', lang),
      HomeCollectionKind.highlight =>
        AppLocalizations.getMenuText('highlights', lang),
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
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(_iconFor(item.kind), size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$surahName · $refLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle:
                            noteSnippet != null ? FontStyle.italic : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.formatHomeRelativeTime(item.at, lang),
                style: textTheme.labelSmall?.copyWith(
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
