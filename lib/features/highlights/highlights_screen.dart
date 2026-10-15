import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/undoable_dismissible.dart';
import 'package:quran_offline/features/library/library_index.dart';
import 'package:quran_offline/features/library/library_relative_time.dart';
import 'package:quran_offline/features/library/verse_translation.dart';
import 'package:quran_offline/features/library/widgets/library_action_sheet.dart';
import 'package:quran_offline/features/library/widgets/library_empty_state.dart';
import 'package:quran_offline/features/library/widgets/library_marked_text.dart';

class HighlightsScreen extends ConsumerStatefulWidget {
  const HighlightsScreen({super.key, this.query = ''});

  final String query;

  @override
  ConsumerState<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends ConsumerState<HighlightsScreen> {
  int? _filterColor;
  final Set<String> _hidden = {};

  String _keyFor(Highlight highlight) =>
      'highlight:${highlight.surahId}:${highlight.ayahNo}';

  @override
  Widget build(BuildContext context) {
    ref.watch(highlightRefreshProvider);
    final highlightsAsync = ref.watch(highlightsProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;

    return highlightsAsync.when(
      data: (highlights) {
        return surahsAsync.when(
          data: (surahs) {
            final visible = highlights
                .where((highlight) => !_hidden.contains(_keyFor(highlight)))
                .toList();
            final usedColors = _usedColors(visible);
            final filtered = visible.where((highlight) {
              if (_filterColor == null) return true;
              return highlightColorsMatch(highlight.color, _filterColor!);
            }).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (visible.isEmpty) {
              return LibraryEmptyState(
                message: AppLocalizations.getSubtitleText('highlights_empty', lang),
                icon: Icons.highlight_outlined,
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    children: [
                      _FilterPill(
                        label: AppLocalizations.getSettingsText('filter_all', lang),
                        selected: _filterColor == null,
                        onTap: () => setState(() => _filterColor = null),
                      ),
                      for (final color in usedColors) ...[
                        const SizedBox(width: 8),
                        _ColorDot(
                          color: highlightDisplayColor(color),
                          selected: _filterColor != null &&
                              highlightColorsMatch(_filterColor!, color),
                          onTap: () => setState(() {
                            _filterColor = _filterColor != null &&
                                    highlightColorsMatch(_filterColor!, color)
                                ? null
                                : color;
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? LibraryEmptyState(
                          message: AppLocalizations.getSubtitleText(
                            'highlights_no_results',
                            lang,
                          ),
                          icon: Icons.highlight_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final highlight = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HighlightCard(
                                highlight: highlight,
                                surah: librarySurah(surahs, highlight.surahId),
                                language: settings.language,
                                appLanguage: lang,
                                query: widget.query,
                                onDelete: () => _delete(highlight, lang),
                              ),
                            );
                          },
                        ),
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

  List<int> _usedColors(List<Highlight> highlights) {
    final present = highlights.map((h) => normalizeHighlightColor(h.color)).toSet();
    final ordered = <int>[];
    for (final color in highlightColors) {
      final normalized = normalizeHighlightColor(color);
      if (present.contains(normalized)) ordered.add(normalized);
    }
    for (final color in present) {
      if (!ordered.contains(color)) ordered.add(color);
    }
    return ordered;
  }

  void _delete(Highlight highlight, String lang) {
    beginLibraryUndoDelete(
      isMounted: () => mounted,
      setState: setState,
      hidden: _hidden,
      entryKey: _keyFor(highlight),
      context: context,
      message: AppLocalizations.libraryDeleted('highlight', lang),
      undoLabel: AppLocalizations.libraryUndo(lang),
      delete: () => removeHighlight(ref, highlight.surahId, highlight.ayahNo),
      restore: () => restoreHighlightEntry(ref, highlight),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.primary : colorScheme.surface.withValues(alpha: 0.94),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colorScheme.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 18, height: 18),
          ),
        ),
      ),
    );
  }
}

class _HighlightCard extends ConsumerWidget {
  const _HighlightCard({
    required this.highlight,
    required this.surah,
    required this.language,
    required this.appLanguage,
    required this.query,
    required this.onDelete,
  });

  final Highlight highlight;
  final SurahInfo surah;
  final String language;
  final String appLanguage;
  final String query;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = highlightDisplayColor(highlight.color);
    return FutureBuilder<Verse?>(
      future: ref.read(databaseProvider).getVerse(highlight.surahId, highlight.ayahNo),
      builder: (context, snapshot) {
        final verse = snapshot.data;
        final arabic = verse?.arabic ?? '';
        final translation = verseTranslation(verse, language);
        final when = formatLibraryRelativeTime(
          highlight.createdAt,
          DateTime.now(),
          appLanguage,
        );
        final copyText = libraryCopyText(
          surahName: surah.englishName,
          surahId: highlight.surahId,
          ayahNo: highlight.ayahNo,
          arabic: arabic,
          translation: translation,
        );

        return UndoableDismissible(
          dismissKey: ValueKey('highlight-${highlight.surahId}-${highlight.ayahNo}'),
          backgroundLabel: AppLocalizations.librarySwipeDelete(appLanguage),
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
              onTap: () => openLibraryReader(
                context,
                ref,
                highlight.surahId,
                highlight.ayahNo,
              ),
              onLongPress: () {
                showLibraryActionSheet(
                  context: context,
                  language: appLanguage,
                  title: '${surah.englishName} · QS ${highlight.surahId}:${highlight.ayahNo}',
                  preview: translation,
                  copyLabel: AppLocalizations.libraryCopy(appLanguage),
                  deleteLabel: AppLocalizations.libraryDeleteAction(
                    'highlight',
                    appLanguage,
                  ),
                  onOpen: () => openLibraryReader(
                    context,
                    ref,
                    highlight.surahId,
                    highlight.ayahNo,
                  ),
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
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LibraryMarkedText(
                            text: '${surah.englishName} · QS ${highlight.surahId}:${highlight.ayahNo}',
                            query: query,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Text(
                          when,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LibraryArabicLine(
                      arabic: arabic,
                      query: query,
                      verseHighlight: tint,
                      fontSize: 22,
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
