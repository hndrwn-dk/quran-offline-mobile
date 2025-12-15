import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/features/read/juz_list_view.dart';
import 'package:quran_offline/features/read/page_list_view.dart';
import 'package:quran_offline/features/read/surah_list_view.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class ReadScreen extends ConsumerWidget {
  const ReadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readMode = ref.watch(readModeProvider);
    final isLargeScreen = Responsive.isLargeScreen(context);

    if (isLargeScreen) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.menu_book_outlined,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Qur'an",
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Read and reflect',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _CustomSegmentedButton(
                            selectedMode: readMode,
                            onModeChanged: (mode) {
                              ref.read(readModeProvider.notifier).state = mode;
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: switch (readMode) {
                        ReadMode.surah => const SurahListView(),
                        ReadMode.juz => const JuzListView(),
                        ReadMode.pages => const PageListView(),
                      },
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              const Expanded(
                child: ReaderScreen(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.menu_book_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Qur'an",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Read and reflect',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CustomSegmentedButton(
                    selectedMode: readMode,
                    onModeChanged: (mode) {
                      ref.read(readModeProvider.notifier).state = mode;
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (readMode) {
                ReadMode.surah => const SurahListView(),
                ReadMode.juz => const JuzListView(),
                ReadMode.pages => const PageListView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom segmented button with icons, styled like Material You chips
class _CustomSegmentedButton extends StatelessWidget {
  final ReadMode selectedMode;
  final ValueChanged<ReadMode> onModeChanged;

  const _CustomSegmentedButton({
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        _CustomSegmentButton(
          mode: ReadMode.surah,
          icon: Icons.menu_book_outlined,
          label: 'Surah',
          isSelected: selectedMode == ReadMode.surah,
          onTap: () => onModeChanged(ReadMode.surah),
        ),
        const SizedBox(width: 8),
        _CustomSegmentButton(
          mode: ReadMode.juz,
          icon: Icons.library_books_outlined,
          label: 'Juz',
          isSelected: selectedMode == ReadMode.juz,
          onTap: () => onModeChanged(ReadMode.juz),
        ),
        const SizedBox(width: 8),
        _CustomSegmentButton(
          mode: ReadMode.pages,
          icon: Icons.auto_stories_outlined,
          label: 'Mushaf',
          isSelected: selectedMode == ReadMode.pages,
          onTap: () => onModeChanged(ReadMode.pages),
        ),
      ],
    );
  }
}

class _CustomSegmentButton extends StatelessWidget {
  final ReadMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomSegmentButton({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : colorScheme.outline.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

