import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
import 'package:quran_offline/core/widgets/floating_nav_bar.dart';
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
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              Container(
                width: 320,
                color: colorScheme.canvas,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 4, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ReadScreenTitle(appLanguage: appLanguage),
                          ),
                          _ReadSearchButton(searchBarKey: _searchBarKey),
                        ],
                      ),
                    ),
                    QuickSearchBar(key: _searchBarKey),
                    ReadModeSegmentTabs(
                      selectedMode: readMode,
                      onModeChanged: _setReadMode,
                    ),
                    Expanded(
                      child: _ReadModeStack(
                        readMode: readMode,
                        onSwipe: (isNext) =>
                            _handleModeNavigation(readMode, isNext),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colorScheme.hairline,
              ),
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
      appBar: AppLargeTitleBar(
        title: AppLocalizations.getSubtitleText('read_title', appLanguage),
        subtitle: AppLocalizations.getSubtitleText(
          'read_subtitle',
          appLanguage,
        ),
        actions: [
          _ReadSearchButton(searchBarKey: _searchBarKey),
          const SizedBox(width: 8),
        ],
      ),
      body: HomeBackdrop(
        child: FloatingNavBarInset(
          child: Column(
            children: [
              QuickSearchBar(key: _searchBarKey),
              ReadModeSegmentTabs(
                selectedMode: readMode,
                onModeChanged: _setReadMode,
              ),
              Expanded(
                child: _ReadModeStack(
                  readMode: readMode,
                  onSwipe: (isNext) => _handleModeNavigation(readMode, isNext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggles the inline [QuickSearchBar] (phone AppBar and the >= 840dp column).
class _ReadSearchButton extends StatelessWidget {
  const _ReadSearchButton({required this.searchBarKey});

  final GlobalKey<QuickSearchBarState> searchBarKey;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('read_search_button'),
      icon: const Icon(Icons.search),
      iconSize: 22,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () {
        searchBarKey.currentState?.toggle();
      },
    );
  }
}

/// Large left-aligned title for the >= 840dp column (the phone layout uses
/// [AppLargeTitleBar]).
class _ReadScreenTitle extends StatelessWidget {
  const _ReadScreenTitle({required this.appLanguage});

  final String appLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.getSubtitleText('read_title', appLanguage),
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.getSubtitleText('read_subtitle', appLanguage),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Keeps Surah/Juz/Mushaf lists mounted so tab switches do not flash an empty body.
class _ReadModeStack extends StatelessWidget {
  const _ReadModeStack({
    required this.readMode,
    required this.onSwipe,
  });

  final ReadMode readMode;
  final ValueChanged<bool> onSwipe;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: readMode.index,
      children: [
        _HorizontalSwipeShell(
          readMode: ReadMode.surah,
          onSwipe: onSwipe,
          child: const SurahListView(),
        ),
        _HorizontalSwipeShell(
          readMode: ReadMode.juz,
          onSwipe: onSwipe,
          child: const JuzListView(),
        ),
        _HorizontalSwipeShell(
          readMode: ReadMode.pages,
          onSwipe: onSwipe,
          child: const PageListView(),
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
