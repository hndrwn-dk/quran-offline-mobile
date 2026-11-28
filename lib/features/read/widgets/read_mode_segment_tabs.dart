import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';

/// iOS-style segment control for Surah / Juz / Mushaf on the Baca tab.
class ReadModeSegmentTabs extends ConsumerWidget {
  const ReadModeSegmentTabs({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final ReadMode selectedMode;
  final ValueChanged<ReadMode> onModeChanged;

  static const _modes = [
    ReadMode.surah,
    ReadMode.juz,
    ReadMode.pages,
  ];

  static IconData _iconFor(ReadMode mode) {
    return switch (mode) {
      ReadMode.surah => Icons.menu_book_outlined,
      ReadMode.juz => Icons.library_books_outlined,
      ReadMode.pages => Icons.auto_stories_outlined,
    };
  }

  static String _labelFor(ReadMode mode, String appLanguage) {
    return switch (mode) {
      ReadMode.surah => AppLocalizations.getMenuText('surah', appLanguage),
      ReadMode.juz => AppLocalizations.getMenuText('juz', appLanguage),
      ReadMode.pages => AppLocalizations.getMenuText('mushaf', appLanguage),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    // The selected segment must read as raised: in dark the card fill is
    // darker than the tint, so the two swap.
    final isDark = colorScheme.brightness == Brightness.dark;
    final trackColor = isDark ? colorScheme.card : colorScheme.tint;
    final selectedColor = isDark ? colorScheme.tint : colorScheme.card;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kAppContentHorizontalInset,
        kAppBodyTopInset,
        kAppContentHorizontalInset,
        8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: _modes.map((mode) {
              final selected = mode == selectedMode;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onModeChanged(mode),
                    borderRadius: BorderRadius.circular(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      constraints: const BoxConstraints(minHeight: 38),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? selectedColor
                            : selectedColor.withValues(alpha: 0),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconFor(mode),
                            size: 16,
                            color: selected
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _labelFor(mode, appLanguage),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
