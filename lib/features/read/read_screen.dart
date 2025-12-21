import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/juz_list_view.dart';
import 'package:quran_offline/features/read/page_list_view.dart';
import 'package:quran_offline/features/read/surah_list_view.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

class ReadScreen extends ConsumerStatefulWidget {
  const ReadScreen({super.key});

  @override
  ConsumerState<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends ConsumerState<ReadScreen> {
  double _swipeStartX = 0.0;
  double _swipeStartY = 0.0;
  bool _isSwiping = false;

  void _handleModeNavigation(ReadMode currentMode, bool isNext) {
    final newMode = switch (currentMode) {
      ReadMode.surah => isNext ? ReadMode.juz : null,
      ReadMode.juz => isNext ? ReadMode.pages : ReadMode.surah,
      ReadMode.pages => isNext ? null : ReadMode.juz,
    };
    
    if (newMode != null) {
      ref.read(readModeProvider.notifier).state = newMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readMode = ref.watch(readModeProvider);
    final settings = ref.watch(settingsProvider);
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
                                    AppLocalizations.getSubtitleText('read_subtitle', settings.appLanguage),
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
                      child: GestureDetector(
                        onHorizontalDragStart: (details) {
                          _swipeStartX = details.globalPosition.dx;
                          _swipeStartY = details.globalPosition.dy;
                          _isSwiping = false;
                        },
                        onHorizontalDragUpdate: (details) {
                          final deltaX = details.globalPosition.dx - _swipeStartX;
                          final deltaY = details.globalPosition.dy - _swipeStartY;
                          // Only consider it a horizontal swipe if horizontal movement is significantly greater than vertical
                          if (deltaX.abs() > 20 && deltaX.abs() > deltaY.abs() * 1.5) {
                            _isSwiping = true;
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          if (!_isSwiping) return;
                          
                          final deltaX = details.velocity.pixelsPerSecond.dx;
                          final deltaY = details.velocity.pixelsPerSecond.dy;
                          // Minimum swipe velocity threshold (pixels per second)
                          // Also ensure horizontal movement is greater than vertical
                          const swipeThreshold = 300.0;
                          
                          if (deltaX.abs() > swipeThreshold && deltaX.abs() > deltaY.abs()) {
                            // Swipe left (negative deltaX) = next mode
                            // Swipe right (positive deltaX) = previous mode
                            final isNext = deltaX < 0;
                            _handleModeNavigation(readMode, isNext);
                          }
                          
                          _isSwiping = false;
                        },
                        child: switch (readMode) {
                          ReadMode.surah => const SurahListView(),
                          ReadMode.juz => const JuzListView(),
                          ReadMode.pages => const PageListView(),
                        },
                      ),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Qur'an",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.getSubtitleText('read_subtitle', settings.appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52), // 6 + 34 (button) + 6 + 1 (divider) + 5 (buffer)
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    _CustomSegmentedButton(
                      selectedMode: readMode,
                      onModeChanged: (mode) {
                        ref.read(readModeProvider.notifier).state = mode;
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          _swipeStartX = details.globalPosition.dx;
          _swipeStartY = details.globalPosition.dy;
          _isSwiping = false;
        },
        onHorizontalDragUpdate: (details) {
          final deltaX = details.globalPosition.dx - _swipeStartX;
          final deltaY = details.globalPosition.dy - _swipeStartY;
          // Only consider it a horizontal swipe if horizontal movement is significantly greater than vertical
          if (deltaX.abs() > 20 && deltaX.abs() > deltaY.abs() * 1.5) {
            _isSwiping = true;
          }
        },
        onHorizontalDragEnd: (details) {
          if (!_isSwiping) return;
          
          final deltaX = details.velocity.pixelsPerSecond.dx;
          final deltaY = details.velocity.pixelsPerSecond.dy;
          // Minimum swipe velocity threshold (pixels per second)
          // Also ensure horizontal movement is greater than vertical
          const swipeThreshold = 300.0;
          
          if (deltaX.abs() > swipeThreshold && deltaX.abs() > deltaY.abs()) {
            // Swipe left (negative deltaX) = next mode
            // Swipe right (positive deltaX) = previous mode
            final isNext = deltaX < 0;
            _handleModeNavigation(readMode, isNext);
          }
          
          _isSwiping = false;
        },
        child: switch (readMode) {
          ReadMode.surah => Column(
              children: [
                const LastReadCard(),
                const Expanded(child: SurahListView()),
              ],
            ),
          ReadMode.juz => Column(
              children: [
                const LastReadCard(),
                const Expanded(child: JuzListView()),
              ],
            ),
          ReadMode.pages => Column(
              children: [
                const LastReadCard(),
                const Expanded(child: PageListView()),
              ],
            ),
        },
      ),
    );
  }
}

/// Custom segmented button with icons, styled like Material You chips
class _CustomSegmentedButton extends ConsumerWidget {
  final ReadMode selectedMode;
  final ValueChanged<ReadMode> onModeChanged;

  const _CustomSegmentedButton({
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    
    return Row(
      children: [
        _CustomSegmentButton(
          mode: ReadMode.surah,
          icon: Icons.menu_book_outlined,
          label: AppLocalizations.getMenuText('surah', appLanguage),
          isSelected: selectedMode == ReadMode.surah,
          onTap: () => onModeChanged(ReadMode.surah),
        ),
        const SizedBox(width: 8),
        _CustomSegmentButton(
          mode: ReadMode.juz,
          icon: Icons.library_books_outlined,
          label: AppLocalizations.getMenuText('juz', appLanguage),
          isSelected: selectedMode == ReadMode.juz,
          onTap: () => onModeChanged(ReadMode.juz),
        ),
        const SizedBox(width: 8),
        _CustomSegmentButton(
          mode: ReadMode.pages,
          icon: Icons.auto_stories_outlined,
          label: AppLocalizations.getMenuText('mushaf', appLanguage),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Reduce padding if space is limited (less than 80px width)
              final horizontalPadding = constraints.maxWidth < 80 ? 8.0 : 12.0;
              
              return Container(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
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
                child: ClipRect(
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
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

