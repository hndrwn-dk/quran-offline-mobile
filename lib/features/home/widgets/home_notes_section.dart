import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/home/widgets/home_section_link.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

const _homeNotesLimit = 2;

class HomeNotesSection extends ConsumerWidget {
  const HomeNotesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final notesAsync = ref.watch(notesProvider);
    final surahsAsync = ref.watch(surahNamesProvider);

    return notesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (notes) => surahsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (surahs) {
          final recent = [...notes]
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final preview = recent.take(_homeNotesLimit).toList();
          final hasNotes = preview.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeSectionHeader(
                  title: AppLocalizations.getHomeNotesSectionTitle(lang),
                  linkLabel: AppLocalizations.getHomeAllNotesLink(lang),
                  onLinkPressed: () => _openAllNotes(ref),
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
                    child: hasNotes
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: preview.asMap().entries.map(
                              (entry) => _NotePreviewRow(
                                note: entry.value,
                                surahName: _surahName(surahs, entry.value.surahId),
                                lang: lang,
                                isLast: entry.key == preview.length - 1,
                                onTap: () => _openNoteAyah(
                                  context,
                                  ref,
                                  entry.value.surahId,
                                  entry.value.ayahNo,
                                ),
                              ),
                            ).toList(),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              AppLocalizations.getHomeNotesEmpty(lang),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String? _previewSnippet(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _surahName(List<SurahInfo> surahs, int surahId) {
    for (final surah in surahs) {
      if (surah.id == surahId) return surah.englishName;
    }
    return 'Surah $surahId';
  }

  void _openAllNotes(WidgetRef ref) {
    ref.read(librarySubTabProvider.notifier).state = 1;
    ref.read(currentTabProvider.notifier).state = AppTab.library;
  }

  void _openNoteAyah(
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

class _NotePreviewRow extends StatelessWidget {
  const _NotePreviewRow({
    required this.note,
    required this.surahName,
    required this.lang,
    required this.isLast,
    required this.onTap,
  });

  final Note note;
  final String surahName;
  final String lang;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final refLabel = AppLocalizations.formatDuaAyahRef(
      note.surahId,
      note.ayahNo,
      note.ayahNo,
      lang,
    );
    final body = HomeNotesSection._previewSnippet(note.note);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$surahName · $refLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                  Text(
                    AppLocalizations.formatHomeRelativeTime(note.updatedAt, lang),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                  ),
                ],
              ),
              if (body != null) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
