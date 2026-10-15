import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/undoable_dismissible.dart';
import 'package:quran_offline/features/bookmarks/open_bookmark.dart';
import 'package:quran_offline/features/library/library_index.dart';
import 'package:quran_offline/features/library/library_relative_time.dart';
import 'package:quran_offline/features/library/library_search.dart';
import 'package:quran_offline/features/library/widgets/library_action_sheet.dart';
import 'package:quran_offline/features/library/widgets/library_marked_text.dart';
import 'package:quran_offline/features/reader/widgets/note_editor_dialog.dart';

class LibrarySearchView extends ConsumerStatefulWidget {
  const LibrarySearchView({
    super.key,
    required this.query,
    required this.onSearchQuran,
  });

  final String query;
  final ValueChanged<String> onSearchQuran;

  @override
  ConsumerState<LibrarySearchView> createState() => _LibrarySearchViewState();
}

class _LibrarySearchViewState extends ConsumerState<LibrarySearchView> {
  LibrarySearchKind? _kind;
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final index = ref.watch(librarySearchIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return index.when(
      data: (rows) {
        final matched = rows.where((row) {
          if (_hidden.contains(row.entryKey)) return false;
          return libraryEntryMatches(row.item, widget.query);
        }).toList();
        final counts = <LibrarySearchKind, int>{};
        for (final row in matched) {
          counts[row.item.kind] = (counts[row.item.kind] ?? 0) + 1;
        }
        final visible = _kind == null
            ? matched
            : matched.where((row) => row.item.kind == _kind).toList();
        final query = widget.query.trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  _chip(
                    null,
                    AppLocalizations.getSettingsText('filter_all', lang),
                    matched.length,
                    lang,
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    LibrarySearchKind.bookmark,
                    AppLocalizations.getMenuText('bookmarks', lang),
                    counts[LibrarySearchKind.bookmark] ?? 0,
                    lang,
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    LibrarySearchKind.note,
                    AppLocalizations.getMenuText('notes', lang),
                    counts[LibrarySearchKind.note] ?? 0,
                    lang,
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    LibrarySearchKind.highlight,
                    AppLocalizations.getMenuText('highlights', lang),
                    counts[LibrarySearchKind.highlight] ?? 0,
                    lang,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                AppLocalizations.librarySearchScope(lang),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _Empty(
                      query: query,
                      lang: lang,
                      onSearch: query.isEmpty
                          ? null
                          : () => widget.onSearchQuran(query),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        for (final kind in LibrarySearchKind.values)
                          if (_kind == null || _kind == kind)
                            ..._section(
                              kind,
                              visible.where((row) => row.item.kind == kind).toList(),
                              lang,
                            ),
                      ],
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _chip(
    LibrarySearchKind? kind,
    String label,
    int count,
    String lang,
  ) {
    return FilterChip(
      label: Text(AppLocalizations.libraryFilterChip(label, count)),
      selected: _kind == kind,
      onSelected: (_) => setState(() => _kind = kind),
    );
  }

  List<Widget> _section(
    LibrarySearchKind kind,
    List<LibrarySearchRow> rows,
    String lang,
  ) {
    if (rows.isEmpty) return const [];
    final label = switch (kind) {
      LibrarySearchKind.bookmark => AppLocalizations.getMenuText('bookmarks', lang),
      LibrarySearchKind.note => AppLocalizations.getMenuText('notes', lang),
      LibrarySearchKind.highlight => AppLocalizations.getMenuText('highlights', lang),
    };
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(
          '${label.toUpperCase()} · ${rows.length}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SearchCard(
            row: row,
            query: widget.query,
            lang: lang,
            onDelete: () => _delete(row, lang),
          ),
        ),
    ];
  }

  void _delete(LibrarySearchRow row, String lang) {
    beginLibraryUndoDelete(
      isMounted: () => mounted,
      setState: setState,
      hidden: _hidden,
      entryKey: row.entryKey,
      context: context,
      message: libraryDeletedMessage(row.item.kind, lang),
      undoLabel: AppLocalizations.libraryUndo(lang),
      delete: () => _deleteRow(row),
      restore: () => _restoreRow(row),
    );
  }

  Future<void> _deleteRow(LibrarySearchRow row) {
    return switch (row.item.kind) {
      LibrarySearchKind.bookmark =>
        deleteBookmarksBulk(ref, [row.bookmark!]),
      LibrarySearchKind.note =>
        deleteNote(ref, row.noteEntry!.surahId, row.noteEntry!.ayahNo),
      LibrarySearchKind.highlight =>
        removeHighlight(ref, row.highlight!.surahId, row.highlight!.ayahNo),
    };
  }

  Future<void> _restoreRow(LibrarySearchRow row) {
    return switch (row.item.kind) {
      LibrarySearchKind.bookmark => restoreBookmarkEntry(ref, row.bookmark!),
      LibrarySearchKind.note => restoreNoteEntry(ref, row.noteEntry!),
      LibrarySearchKind.highlight => restoreHighlightEntry(ref, row.highlight!),
    };
  }
}

class _SearchCard extends ConsumerWidget {
  const _SearchCard({
    required this.row,
    required this.query,
    required this.lang,
    required this.onDelete,
  });

  final LibrarySearchRow row;
  final String query;
  final String lang;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = row.item;
    final when = formatLibraryRelativeTime(row.time, DateTime.now(), lang);
    final snippet = item.kind == LibrarySearchKind.note && item.note.isNotEmpty
        ? item.note
        : item.translation;
    final copyText = libraryCopyText(
      surahName: item.surahName,
      surahId: item.surahId,
      ayahNo: item.ayahNo,
      arabic: item.arabic,
      translation: item.translation,
      note: item.note,
    );

    return UndoableDismissible(
      dismissKey: ValueKey('search-${row.entryKey}'),
      backgroundLabel: AppLocalizations.librarySwipeDelete(lang),
      onDismissed: onDelete,
      child: Material(
        color: colorScheme.surface.withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context, ref),
          onLongPress: () {
            showLibraryActionSheet(
              context: context,
              language: lang,
              title: '${item.surahName} · QS ${item.surahId}:${item.ayahNo}',
              preview: snippet,
              copyLabel: item.kind == LibrarySearchKind.note
                  ? AppLocalizations.libraryCopyVerseAndNote(lang)
                  : AppLocalizations.libraryCopy(lang),
              deleteLabel: AppLocalizations.libraryDeleteAction(
                libraryKindKey(item.kind),
                lang,
              ),
              onOpen: () => _open(context, ref),
              onEdit: item.kind == LibrarySearchKind.note
                  ? () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => NoteEditorDialog(
                          surahId: item.surahId,
                          ayahNo: item.ayahNo,
                          existingNote: item.note,
                        ),
                      );
                    }
                  : null,
              onCopy: () => copyLibraryText(copyText),
              onDelete: onDelete,
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (row.highlight != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: highlightDisplayColor(row.highlight!.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: LibraryMarkedText(
                        text: '${item.surahName} · QS ${item.surahId}:${item.ayahNo}',
                        query: query,
                        maxLines: 1,
                        style: libraryMetaStyle(context),
                      ),
                    ),
                    Text(
                      when,
                      style: libraryMetaStyle(context),
                    ),
                  ],
                ),
                if (item.kind != LibrarySearchKind.bookmark)
                  LibraryArabicLine(
                    arabic: item.arabic,
                    query: query,
                    fontSize: 20,
                    verseHighlight: row.highlight == null
                        ? null
                        : highlightDisplayColor(row.highlight!.color),
                  ),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  LibraryMarkedText(
                    text: snippet,
                    query: query,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    final item = row.item;
    if (row.bookmark != null) {
      openBookmarkLocation(context, ref, row.bookmark!);
      return;
    }
    openLibraryReader(context, ref, item.surahId, item.ayahNo);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.query,
    required this.lang,
    required this.onSearch,
  });

  final String query;
  final String lang;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              query.isEmpty
                  ? AppLocalizations.getSubtitleText('library_no_results', lang)
                  : AppLocalizations.librarySearchEmpty(query, lang),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
            if (onSearch != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onSearch,
                child: Text(AppLocalizations.librarySearchInQuran(lang)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
