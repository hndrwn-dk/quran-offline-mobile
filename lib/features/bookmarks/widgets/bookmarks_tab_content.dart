import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_surface_card.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';
import 'package:quran_offline/core/widgets/undoable_dismissible.dart';
import 'package:quran_offline/features/bookmarks/open_bookmark.dart';
import 'package:quran_offline/features/library/bookmark_groups.dart';
import 'package:quran_offline/features/library/library_index.dart';
import 'package:quran_offline/features/library/library_relative_time.dart';
import 'package:quran_offline/features/library/verse_translation.dart';
import 'package:quran_offline/features/library/widgets/library_action_sheet.dart';
import 'package:quran_offline/features/library/widgets/library_empty_state.dart';
import 'package:quran_offline/features/library/widgets/library_marked_text.dart';

class BookmarksTabContent extends ConsumerStatefulWidget {
  const BookmarksTabContent({super.key, this.query = ''});

  final String query;

  @override
  ConsumerState<BookmarksTabContent> createState() => _BookmarksTabContentState();
}

class _BookmarksTabContentState extends ConsumerState<BookmarksTabContent> {
  bool _newestFirst = true;
  final Set<String> _hidden = {};

  String _keyFor(Bookmark bookmark) =>
      'bookmark:${bookmark.surahId}:${bookmark.ayahNo}';

  @override
  Widget build(BuildContext context) {
    ref.watch(bookmarkRefreshProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return bookmarksAsync.when(
      data: (bookmarks) {
        return surahsAsync.when(
          data: (surahs) {
            final visible = bookmarks
                .where((bookmark) => !_hidden.contains(_keyFor(bookmark)))
                .toList();
            if (visible.isEmpty) {
              return LibraryEmptyState(
                message: AppLocalizations.getSubtitleText('bookmarks_empty', lang),
                icon: Icons.bookmark_outline,
              );
            }
            final groups = groupBookmarks(visible, newestFirst: _newestFirst);
            final sortLabel = _newestFirst
                ? AppLocalizations.librarySortNewest(lang)
                : AppLocalizations.getSettingsText('sort_surah', lang);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.libraryPerSurah(lang).toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                        ),
                      ),
                      PopupMenuButton<bool>(
                        initialValue: _newestFirst,
                        onSelected: (value) => setState(() => _newestFirst = value),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: true,
                            child: Text(AppLocalizations.librarySortNewest(lang)),
                          ),
                          PopupMenuItem(
                            value: false,
                            child: Text(
                              AppLocalizations.getSettingsText('sort_surah', lang),
                            ),
                          ),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sortLabel,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < groups.length; i++)
                  _SurahGroup(
                    group: groups[i],
                    surah: librarySurah(surahs, groups[i].surahId),
                    language: settings.language,
                    appLanguage: lang,
                    query: widget.query,
                    isLast: i == groups.length - 1,
                    onOpen: (bookmark) => openBookmarkLocation(context, ref, bookmark),
                    onCopy: (text) => copyLibraryText(text),
                    onDelete: (bookmark) => _delete(bookmark, lang),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _delete(Bookmark bookmark, String lang) {
    beginLibraryUndoDelete(
      isMounted: () => mounted,
      setState: setState,
      hidden: _hidden,
      entryKey: _keyFor(bookmark),
      context: context,
      message: AppLocalizations.libraryDeleted('bookmark', lang),
      undoLabel: AppLocalizations.libraryUndo(lang),
      delete: () => deleteBookmarksBulk(ref, [bookmark]),
      restore: () => restoreBookmarkEntry(ref, bookmark),
    );
  }
}

class _SurahGroup extends ConsumerWidget {
  const _SurahGroup({
    required this.group,
    required this.surah,
    required this.language,
    required this.appLanguage,
    required this.query,
    required this.isLast,
    required this.onOpen,
    required this.onCopy,
    required this.onDelete,
  });

  final SurahBookmarkGroup group;
  final SurahInfo surah;
  final String language;
  final String appLanguage;
  final String query;
  final bool isLast;
  final Future<void> Function(Bookmark bookmark) onOpen;
  final Future<void> Function(String text) onCopy;
  final void Function(Bookmark bookmark) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LibraryMarkedText(
                      text: surah.englishName,
                      query: query,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.librarySurahBookmarkMeta(
                        surah.id,
                        group.items.length,
                        appLanguage,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (surah.arabicName.isNotEmpty)
                QuranArabicText(
                  arabic: surah.arabicName,
                  fontSize: 18,
                  defaultColor: colorScheme.primary.withValues(alpha: 0.7),
                  height: 1.4,
                  selectable: false,
                ),
            ],
          ),
        ),
        for (var i = 0; i < group.items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _BookmarkRow(
            bookmark: group.items[i],
            surah: surah,
            language: language,
            appLanguage: appLanguage,
            query: query,
            onOpen: onOpen,
            onCopy: onCopy,
            onDelete: onDelete,
          ),
        ],
        if (!isLast) const SizedBox(height: 20),
      ],
    );
  }
}

class _BookmarkRow extends ConsumerWidget {
  const _BookmarkRow({
    required this.bookmark,
    required this.surah,
    required this.language,
    required this.appLanguage,
    required this.query,
    required this.onOpen,
    required this.onCopy,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final SurahInfo surah;
  final String language;
  final String appLanguage;
  final String query;
  final Future<void> Function(Bookmark bookmark) onOpen;
  final Future<void> Function(String text) onCopy;
  final void Function(Bookmark bookmark) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<Verse?>(
      future: ref.read(databaseProvider).getVerse(bookmark.surahId, bookmark.ayahNo),
      builder: (context, snapshot) {
        final verse = snapshot.data;
        final arabic = verse?.arabic ?? '';
        final translation = verseTranslation(verse, language);
        final when = formatLibraryRelativeTime(
          bookmark.createdAt,
          DateTime.now(),
          appLanguage,
        );
        final copyText = libraryCopyText(
          surahName: surah.englishName,
          surahId: bookmark.surahId,
          ayahNo: bookmark.ayahNo,
          arabic: arabic,
          translation: translation,
        );

        return UndoableDismissible(
          dismissKey: ValueKey('bookmark-${bookmark.surahId}-${bookmark.ayahNo}'),
          backgroundLabel: AppLocalizations.librarySwipeDelete(appLanguage),
          borderRadius: AppSurfaceCard.borderRadius,
          onDismissed: () => onDelete(bookmark),
          child: AppSurfaceCard(
            onTap: () => onOpen(bookmark),
            onLongPress: () {
              showLibraryActionSheet(
                context: context,
                language: appLanguage,
                title: '${surah.englishName} · QS ${bookmark.surahId}:${bookmark.ayahNo}',
                preview: translation,
                copyLabel: AppLocalizations.libraryCopy(appLanguage),
                deleteLabel: AppLocalizations.libraryDeleteAction(
                  'bookmark',
                  appLanguage,
                ),
                onOpen: () => onOpen(bookmark),
                onCopy: () => onCopy(copyText),
                onDelete: () => onDelete(bookmark),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LibraryArabicLine(
                  arabic: arabic,
                  query: query,
                  ayahNo: bookmark.ayahNo,
                ),
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  LibraryMarkedText(
                    text: translation,
                    query: query,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.libraryAyahMeta(
                    bookmark.ayahNo,
                    when,
                    appLanguage,
                  ),
                  style: libraryMetaStyle(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
