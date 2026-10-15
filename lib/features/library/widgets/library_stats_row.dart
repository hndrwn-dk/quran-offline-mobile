import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';

class LibraryStatsRow extends ConsumerWidget {
  const LibraryStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bookmarkRefreshProvider);
    ref.watch(noteRefreshProvider);
    ref.watch(highlightRefreshProvider);

    final lang = ref.watch(settingsProvider).appLanguage;
    final bookmarks = ref.watch(bookmarksProvider).valueOrNull?.length ?? 0;
    final notes = ref.watch(notesProvider).valueOrNull?.length ?? 0;
    final highlights = ref.watch(highlightsProvider).valueOrNull?.length ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kAppContentHorizontalInset,
        kAppBodyTopInset,
        kAppContentHorizontalInset,
        0,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatChip(
            label: _statLabel(
              count: bookmarks,
              menuKey: 'bookmarks',
              lang: lang,
            ),
            colorScheme: colorScheme,
          ),
          _StatChip(
            label: _statLabel(
              count: notes,
              menuKey: 'notes',
              lang: lang,
            ),
            colorScheme: colorScheme,
          ),
          _StatChip(
            label: _statLabel(
              count: highlights,
              menuKey: 'highlights',
              lang: lang,
            ),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  static String _statLabel({
    required int count,
    required String menuKey,
    required String lang,
  }) {
    final name = AppLocalizations.getMenuText(menuKey, lang).toLowerCase();
    return '$count $name';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.colorScheme,
  });

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
