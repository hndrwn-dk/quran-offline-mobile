import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/read/juz_list_view.dart';
import 'package:quran_offline/features/read/page_list_view.dart';
import 'package:quran_offline/features/read/surah_list_view.dart';
import 'package:quran_offline/features/read/widgets/quick_search_bar.dart';
import 'package:quran_offline/features/read/widgets/read_mode_segment_tabs.dart';
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
  final _searchBarKey = GlobalKey<QuickSearchBarState>();

  @override
  void initState() {
    super.initState();
    MushafWarmup.beginSession();
  }

  void _setReadMode(ReadMode mode) {
    if (mode == ReadMode.pages) {
      PlaybackActions.stopIfActive(ref);
    }
    ref.read(readModeProvider.notifier).state = mode;
  }

  void _handleModeNavigation(ReadMode currentMode, bool isNext) {
    final newMode = switch (currentMode) {
      ReadMode.surah => isNext ? ReadMode.juz : null,
      ReadMode.juz => isNext ? ReadMode.pages : ReadMode.surah,
      ReadMode.pages => isNext ? null : ReadMode.juz,
    };

    if (newMode != null) {
      _setReadMode(newMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readMode = ref.watch(readModeProvider);
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final isLargeScreen = Responsive.isLargeScreen(context);

    ref.listen<ReadMode>(readModeProvider, (previous, next) {
      if (next == ReadMode.pages && previous != ReadMode.pages) {
        PlaybackActions.stopIfActive(ref);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readerSplitLayoutProvider.notifier).state = isLargeScreen;
    });

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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _ReadScreenTitle(appLanguage: appLanguage),
                    ),
                    ReadModeSegmentTabs(
                      selectedMode: readMode,
                      onModeChanged: _setReadMode,
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
                          if (deltaX.abs() > 20 &&
                              deltaX.abs() > deltaY.abs() * 1.5) {
                            _isSwiping = true;
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          if (!_isSwiping) return;

                          final deltaX = details.velocity.pixelsPerSecond.dx;
                          final deltaY = details.velocity.pixelsPerSecond.dy;
                          const swipeThreshold = 300.0;

                          if (deltaX.abs() > swipeThreshold &&
                              deltaX.abs() > deltaY.abs()) {
                            _handleModeNavigation(readMode, deltaX < 0);
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

    final colorScheme = Theme.of(context).colorScheme;
    final topTint = HomeBackdrop.topTint(colorScheme);

    return Scaffold(
      backgroundColor: topTint,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
        backgroundColor: topTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
        title: _ReadScreenTitle(appLanguage: appLanguage),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(),
            onPressed: () {
              _searchBarKey.currentState?.toggle();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: HomeBackdrop(
        child: Column(
          children: [
            QuickSearchBar(key: _searchBarKey),
            ReadModeSegmentTabs(
              selectedMode: readMode,
              onModeChanged: _setReadMode,
            ),
            Expanded(
              child: switch (readMode) {
                ReadMode.surah => _HorizontalSwipeShell(
                    readMode: readMode,
                    onSwipe: (isNext) =>
                        _handleModeNavigation(readMode, isNext),
                    child: const SurahListView(),
                  ),
                ReadMode.juz => _HorizontalSwipeShell(
                    readMode: readMode,
                    onSwipe: (isNext) =>
                        _handleModeNavigation(readMode, isNext),
                    child: const JuzListView(),
                  ),
                ReadMode.pages => _HorizontalSwipeShell(
                    readMode: readMode,
                    onSwipe: (isNext) =>
                        _handleModeNavigation(readMode, isNext),
                    child: const PageListView(),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadScreenTitle extends StatelessWidget {
  const _ReadScreenTitle({required this.appLanguage});

  final String appLanguage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.auto_stories,
            size: 18,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.getSubtitleText('read_title', appLanguage),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.getSubtitleText('read_subtitle', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Horizontal swipe to change Surah/Juz/Mushaf — scoped to the list only so
/// reflection/last-read taps are not mistaken for mode swipes.
class _HorizontalSwipeShell extends StatefulWidget {
  const _HorizontalSwipeShell({
    required this.readMode,
    required this.onSwipe,
    required this.child,
  });

  final ReadMode readMode;
  final ValueChanged<bool> onSwipe;
  final Widget child;

  @override
  State<_HorizontalSwipeShell> createState() => _HorizontalSwipeShellState();
}

class _HorizontalSwipeShellState extends State<_HorizontalSwipeShell> {
  double _swipeStartX = 0;
  double _swipeStartY = 0;
  bool _isSwiping = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _swipeStartX = details.globalPosition.dx;
        _swipeStartY = details.globalPosition.dy;
        _isSwiping = false;
      },
      onHorizontalDragUpdate: (details) {
        final deltaX = details.globalPosition.dx - _swipeStartX;
        final deltaY = details.globalPosition.dy - _swipeStartY;
        if (deltaX.abs() > 20 && deltaX.abs() > deltaY.abs() * 1.5) {
          _isSwiping = true;
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_isSwiping) return;

        final deltaX = details.velocity.pixelsPerSecond.dx;
        final deltaY = details.velocity.pixelsPerSecond.dy;
        const swipeThreshold = 300.0;

        if (deltaX.abs() > swipeThreshold && deltaX.abs() > deltaY.abs()) {
          widget.onSwipe(deltaX < 0);
        }

        _isSwiping = false;
      },
      child: widget.child,
    );
  }
}
