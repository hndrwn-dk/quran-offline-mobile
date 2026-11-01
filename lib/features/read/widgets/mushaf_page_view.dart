import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/share/verse_share.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/completed_reading_provider.dart';
import 'package:quran_offline/core/providers/mushaf_navigation_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/resume_hint_provider.dart';
import 'package:quran_offline/core/reading/completed_reading.dart';
import 'package:quran_offline/core/reading/reading_completion_gate.dart';
import 'package:quran_offline/core/reading/reading_scope.dart';
import 'package:quran_offline/core/review/review_ask_service.dart';
import 'package:quran_offline/core/models/bookmark_open_context.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/reading/reading_activity_service.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';
import 'package:quran_offline/core/utils/system_bottom_inset.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/core/widgets/mushaf_page_frame.dart';
import 'package:quran_offline/core/feedback/feedback_context.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/features/settings/feedback_form_sheet.dart';
import 'package:quran_offline/features/audio/global_recitation_bar.dart';
import 'package:quran_offline/features/read/widgets/mushaf_offline_audio_banner.dart';
import 'package:quran_offline/features/read/widgets/mushaf_gesture_hint_banner.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_number_badge.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:quran_offline/features/read/widgets/mushaf_text_settings_dialog.dart';
import 'package:quran_offline/features/reader/widgets/reader_app_bar.dart';
import 'package:quran_offline/features/reader/widgets/reader_back_button.dart';
import 'package:quran_offline/features/reader/widgets/resume_hint_chip.dart';
import 'package:quran_offline/features/read/widgets/qpc_v2_mushaf_text.dart';

class MushafPageView extends ConsumerStatefulWidget {
  final int initialPage;
  final int? targetSurahId;
  final int? targetAyahNo;

  const MushafPageView({
    super.key,
    required this.initialPage,
    this.targetSurahId,
    this.targetAyahNo,
  });

  @override
  ConsumerState<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends ConsumerState<MushafPageView> {
  late PageController _controller;
  final List<PageController> _retiredControllers = [];
  int? _selectedSurahId;
  int? _selectedAyahNo;
  late int _visiblePageNo;

  /// Page the user last touched (tap/long-press) inside the current spread.
  int? _activePageNo;
  int? _scrollToSurahId;
  int? _scrollToAyahNo;
  bool _programmaticPageChange = false;

  /// True once a two page spread fits this window (set in didChangeDependencies).
  bool _spread = false;

  /// AppBar + badge visibility in framed mode (immersive reading).
  bool _chromeVisible = true;
  bool _chromeInitialized = false;
  bool _lastFramed = false;

  /// True when the current window renders pages in a fixed-aspect frame.
  bool get _framedMode =>
      _spread ||
      MediaQuery.sizeOf(context).width >= kMushafMinSpreadWindowWidth;

  /// True when the user swiped to another spread while recitation is playing.
  bool _userPagedDuringPlayback = false;

  /// Set only when this screen was opened by the cold-start resume.
  ResumeHint? _resumeHint;

  ReadingCompletionGate? _completionGate;
  Timer? _completionTimer;

  /// Pages currently laid out (one page, or the pair of a spread).
  List<int> get _visiblePages {
    if (!_spread) return [_visiblePageNo];
    return mushafSpreadForPage(_visiblePageNo).pages;
  }

  /// Page used for last-read, audio sync and the page indicator.
  int get _currentPageNo {
    final active = _activePageNo;
    if (active != null && _visiblePages.contains(active)) return active;
    return _spread ? mushafSpreadForPage(_visiblePageNo).rightPage : _visiblePageNo;
  }

  int _pagerIndexForPage(int pageNo) {
    if (_spread) return mushafSpreadIndexForPage(pageNo);
    return pageNo - 1;
  }

  @override
  void initState() {
    super.initState();
    _resumeHint = ref.read(resumeHintProvider);
    _completionGate = ReadingCompletionGate(
      minimumSession: Duration.zero,
    )..startSession();
    // Normal mapping: index 0 = page 1, index 603 = page 604
    // With reverse: true, swipe right-to-left = next page (index increases)
    final initialIndex = widget.initialPage - 1;
    _visiblePageNo = widget.initialPage;
    _scrollToSurahId = widget.targetSurahId;
    _scrollToAyahNo = widget.targetAyahNo;
    _controller = PageController(initialPage: initialIndex);
    // Defer provider writes: initState can run mid-build (e.g. a push triggered
    // while another widget is building), and writing during build throws.
    _controller.addListener(_onPageControllerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_resumeHint != null && ref.read(resumeHintProvider) == _resumeHint) {
        ref.read(resumeHintProvider.notifier).state = null;
      }
      ref.read(mushafSessionActiveProvider.notifier).state = true;
      ref.read(mushafVisiblePageProvider.notifier).state = _visiblePageNo;
      MushafWarmup.beginSession(priorityPage: widget.initialPage);
      unawaited(
        MushafLayout.prewarmNeighbors(context, widget.initialPage),
      );
      ref
          .read(lastReadProvider.notifier)
          .saveLastRead(PageSource(widget.initialPage));
      unawaited(_checkCompletionForPage(widget.initialPage));
    });
  }

  void _onPageControllerTick() {
    if (!_controller.hasClients) return;
    final page = _controller.page;
    if (page == null) return;
    MushafWarmup.prefetchDuringSwipe(page);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The spread decision only depends on the window (MediaQuery) so folding,
    // unfolding or rotating rebuilds the pager around the page already in view.
    final media = MediaQuery.of(context);
    final setting = ref.read(settingsProvider).mushafTwoPageSpread;
    final metrics = resolveMushafSpread(
      available: media.size,
      displayFeatures: media.displayFeatures,
      spreadEnabled: setting,
    );
    if (kDebugMode) {
      final features = media.displayFeatures
          .map((f) => '${f.type}/${f.state}@${f.bounds}')
          .join(', ');
      debugPrint(
        '[MushafGate] size=${media.size} dpr=${media.devicePixelRatio} '
        'padding=${media.padding} viewPadding=${media.viewPadding} '
        'features=[$features] -> showSpread=${metrics.showSpread} '
        'page=${metrics.pageSize} (${metrics.reason})',
      );
    }
    if (!_chromeInitialized) {
      _chromeInitialized = true;
      // Framed windows open in immersive mode: the frame grows by the AppBar,
      // badge and system bar height, which is what makes the text bigger.
      _chromeVisible = !(_spread ||
          media.size.width >= kMushafMinSpreadWindowWidth);
      _lastFramed = !_chromeVisible;
      _applySystemUi(chromeVisible: _chromeVisible);
    }
    if (metrics.showSpread == _spread) {
      _syncChromeToMode(media);
      return;
    }
    _setSpreadMode(metrics.showSpread);
    _syncChromeToMode(media);
  }

  /// Phones always show the AppBar; framed windows start immersive and keep the
  /// reader's toggle afterwards.
  void _syncChromeToMode(MediaQueryData media) {
    final framed = _spread || media.size.width >= kMushafMinSpreadWindowWidth;
    if (framed == _lastFramed) return;
    _lastFramed = framed;
    _chromeVisible = !framed;
    _applySystemUi(chromeVisible: _chromeVisible);
  }

  void _setSpreadMode(bool spread) {
    _spread = spread;
    _replaceController();
  }

  /// Applies the system UI mode for framed reading (immersive = more page).
  void _applySystemUi({required bool chromeVisible}) {
    if (!_framedMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return;
    }
    SystemChrome.setEnabledSystemUIMode(
      chromeVisible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  /// Tap on an empty part of the page (margin/gutter) shows/hides the bars.
  void _toggleChrome() {
    if (!mounted) return;
    setState(() => _chromeVisible = !_chromeVisible);
    _applySystemUi(chromeVisible: _chromeVisible);
  }

  void _replaceController() {
    final old = _controller;
    old.removeListener(_onPageControllerTick);
    _controller = PageController(
      initialPage: _pagerIndexForPage(_visiblePageNo),
    );
    _controller.addListener(_onPageControllerTick);
    _retiredControllers.add(old);
    // The old PageView is still attached during this build; dispose after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in _retiredControllers) {
        controller.dispose();
      }
      _retiredControllers.clear();
    });
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _completionGate?.dispose();
    _controller.removeListener(_onPageControllerTick);
    _controller.dispose();
    for (final controller in _retiredControllers) {
      controller.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _checkCompletionForPage(int pageNo) async {
    try {
      final db = ref.read(databaseProvider);
      final pageVerses = await db.getVersesByPage(pageNo);
      if (pageVerses.isEmpty) return;
      final range = JuzPageRange.fromVerses(
        await db.getVersesByJuz(pageVerses.first.juz),
      );
      if (!mounted || _visiblePageNo != pageNo) return;
      _setEndVisible(range?.endPage == pageNo);
    } catch (_) {
      // Completion must never affect reading.
    }
  }

  void _setEndVisible(bool visible) {
    final gate = _completionGate;
    if (gate == null || gate.completed) return;

    gate.setEndVisible(visible);
    if (!visible) {
      _completionTimer?.cancel();
      _completionTimer = null;
      return;
    }

    _completionTimer ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (gate.tick()) {
        _completionTimer?.cancel();
        _completionTimer = null;
        _handleUnitCompleted();
      }
    });
  }

  Future<void> _handleUnitCompleted() async {
    if (!mounted) return;
    final pageNo = _currentPageNo;
    await ref
        .read(lastReadProvider.notifier)
        .saveLastRead(PageSource(pageNo));
    await ref.read(completedReadingProvider.notifier).markCompleted(
          CompletedReading(type: 'page', id: pageNo, pageNo: pageNo),
        );
    unawaited(ref.read(reviewAskServiceProvider).onUnitCompleted());
  }

  Future<void> _goToPage(
    int pageNo, {
    required int surahId,
    int? ayahNo,
  }) async {
    if (!mounted) return;

    setState(() {
      _scrollToSurahId = surahId;
      _scrollToAyahNo = ayahNo;
    });

    if (_visiblePages.contains(pageNo)) return;

    _programmaticPageChange = true;
    _visiblePageNo = pageNo;
    _activePageNo = null;
    ref.read(mushafVisiblePageProvider.notifier).state = pageNo;

    await _controller.animateToPage(
      _pagerIndexForPage(pageNo),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _syncPageToRecitation(AudioPlayerState audio) async {
    if (!audio.isActive || audio.surahId == null || audio.ayahNo == null) {
      return;
    }
    // The reader swiped away on purpose: do not drag them back.
    if (_userPagedDuringPlayback) return;

    final surahId = audio.surahId!;
    final ayahNo = audio.ayahNo!;

    // Highlighting already covers both pages, so only flip spreads when the
    // recitation moves past the last page currently in view.
    var onPage = false;
    for (final pageNo in _visiblePages) {
      if (await MushafLayout.pageContainsRecitation(
        pageNo,
        surahId,
        ayahNo,
      )) {
        onPage = true;
        break;
      }
    }
    if (!mounted || onPage) return;

    final db = ref.read(databaseProvider);
    final lookupAyah = ayahNo == Bismillah.audioAyahNo ? 1 : ayahNo;
    final pageNo = await db.getPageForAyah(surahId, lookupAyah);
    if (!mounted || pageNo == null) return;

    final scrollAyah =
        audio.isPlayingBismillah ? Bismillah.audioAyahNo : ayahNo;
    await _goToPage(pageNo, surahId: surahId, ayahNo: scrollAyah);
  }

  void _onAyahTap(int surahId, int ayahNo, {int? pageNo}) {
    if (pageNo != null) {
      _markUserPage(pageNo);
    }
    setState(() {
      _selectedSurahId = surahId;
      _selectedAyahNo = ayahNo;
    });
    final surahs = ref.read(surahNamesProvider).valueOrNull;
    String? surahName;
    if (surahs != null && surahs.isNotEmpty) {
      surahName = surahs
          .firstWhere(
            (s) => s.id == surahId,
            orElse: () => surahs.first,
          )
          .englishName;
    }
    _userPagedDuringPlayback = false;
    PlaybackActions.playMushafAyah(
      context,
      ref,
      surahId,
      ayahNo,
      surahName: surahName,
    );
  }

  /// Remembers which page of the spread the reader interacted with.
  void _markUserPage(int pageNo) {
    _activePageNo = pageNo;
    if (!mounted) return;
    ref.read(mushafVisiblePageProvider.notifier).state = pageNo;
    ref.read(lastReadProvider.notifier).saveLastRead(PageSource(pageNo));
  }

  void _onBismillahTap(int surahId, {int? pageNo}) {
    _onAyahTap(surahId, Bismillah.audioAyahNo, pageNo: pageNo);
  }

  void _onBismillahLongPress(int surahId, {int? pageNo}) {
    _onAyahLongPress(surahId, Bismillah.audioAyahNo, pageNo: pageNo);
  }

  void _onAyahLongPress(int surahId, int ayahNo, {int? pageNo}) {
    if (pageNo != null) {
      _markUserPage(pageNo);
    }
    setState(() {
      _selectedSurahId = surahId;
      _selectedAyahNo = ayahNo;
    });
    _FlowingMushafText.showAyahSheet(context, ref, surahId, ayahNo);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((s) => s.mushafFontSize));

    ref.listen<bool>(
      settingsProvider.select((s) => s.mushafTwoPageSpread),
      (previous, next) {
        if (previous == next || !mounted) return;
        final media = MediaQuery.of(context);
        final metrics = resolveMushafSpread(
          available: media.size,
          displayFeatures: media.displayFeatures,
          spreadEnabled: next,
        );
        if (metrics.showSpread == _spread) return;
        setState(() => _setSpreadMode(metrics.showSpread));
      },
    );

    ref.listen<AudioPlayerState>(audioPlayerProvider, (previous, next) {
      if (!mounted) return;
      if (!next.isActive) {
        _userPagedDuringPlayback = false;
        setState(() {
          _selectedSurahId = null;
          _selectedAyahNo = null;
        });
        return;
      }
      setState(() {
        _selectedSurahId = next.surahId;
        _selectedAyahNo =
            next.isPlayingBismillah ? null : next.ayahNo;
      });

      final surahChanged = previous?.surahId != next.surahId;
      final ayahChanged = previous?.ayahNo != next.ayahNo;
      if (surahChanged || ayahChanged) {
        _syncPageToRecitation(next);
      }
    });

    ref.listen<MushafJumpRequest?>(mushafJumpRequestProvider, (previous, next) {
      if (!mounted || next == null) return;
      _goToPage(
        next.pageNo,
        surahId: next.surahId,
        ayahNo: next.ayahNo,
      );
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(mushafVisiblePageProvider.notifier).state = null;
          ref.read(mushafSessionActiveProvider.notifier).state = false;
          ref.read(mushafJumpRequestProvider.notifier).state = null;
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              key: ValueKey<bool>(_spread),
              controller: _controller,
              // RTL direction: swipe right-to-left = next page/spread.
              reverse: true,
              onPageChanged: (index) {
                final pageNo =
                    _spread ? mushafSpreadPageForIndex(index) : index + 1;
                _visiblePageNo = pageNo;
                _activePageNo = null;
                ref.read(mushafVisiblePageProvider.notifier).state = pageNo;
                MushafLayout.prewarmNeighbors(context, pageNo);
                if (_programmaticPageChange) {
                  _programmaticPageChange = false;
                } else {
                  if (ref.read(audioPlayerProvider).isActive) {
                    _userPagedDuringPlayback = true;
                  }
                  setState(() {
                    _scrollToSurahId = null;
                    _scrollToAyahNo = null;
                    _selectedSurahId = null;
                    _selectedAyahNo = null;
                  });
                  ref
                      .read(lastReadProvider.notifier)
                      .saveLastRead(PageSource(pageNo));
                  unawaited(_checkCompletionForPage(pageNo));
                }
              },
              itemCount: _spread ? kMushafSpreadCount : kMushafTotalPages,
              itemBuilder: (context, index) {
                // Single: index 0 = page 1, index 603 = page 604 (reverse keeps
                // RTL order). Spread: index 0 = 1|2, index 301 = 603|604.
                if (_spread) {
                  final oddPage = mushafSpreadPageForIndex(index);
                  final evenPage = oddPage + 1;
                  return _MushafSpread(
                    leftPage: evenPage,
                    rightPage: oddPage,
                    chromeVisible: _chromeVisible,
                    onToggleChrome: _toggleChrome,
                    targetSurahId: _scrollToSurahId,
                    targetAyahNo: _scrollToAyahNo,
                    selectedSurahId: _selectedSurahId,
                    selectedAyahNo: _selectedAyahNo,
                    onAyahTap: (surahId, ayahNo, pageNo) =>
                        _onAyahTap(surahId, ayahNo, pageNo: pageNo),
                    onAyahLongPress: (surahId, ayahNo, pageNo) =>
                        _onAyahLongPress(surahId, ayahNo, pageNo: pageNo),
                    onBismillahTap: (surahId, pageNo) =>
                        _onBismillahTap(surahId, pageNo: pageNo),
                    onBismillahLongPress: (surahId, pageNo) =>
                        _onBismillahLongPress(surahId, pageNo: pageNo),
                    onComputed: () {
                      if (evenPage < kMushafTotalPages) {
                        MushafLayout.prewarm(context, evenPage + 1);
                      }
                    },
                  );
                }
                final pageNo = index + 1;
                final framedSingle = MediaQuery.sizeOf(context).width >=
                    kMushafMinSpreadWindowWidth;
                return MushafPage(
                  pageNo: pageNo,
                  // < 600dp: exact 1.0.21+69 flow layout. >= 600dp single page
                  // (Fold portrait, tablet portrait, spread turned off) uses the
                  // same fixed frame as one page of a spread.
                  framed: framedSingle,
                  chromeVisible: _chromeVisible,
                  onToggleChrome: _toggleChrome,
                  targetSurahId: _scrollToSurahId,
                  targetAyahNo: _scrollToAyahNo,
                  selectedSurahId: _selectedSurahId,
                  selectedAyahNo: _selectedAyahNo,
                  onAyahTap: (surahId, ayahNo, pageNo) =>
                      _onAyahTap(surahId, ayahNo, pageNo: pageNo),
                  onAyahLongPress: (surahId, ayahNo, pageNo) =>
                      _onAyahLongPress(surahId, ayahNo, pageNo: pageNo),
                  onBismillahTap: (surahId, pageNo) =>
                      _onBismillahTap(surahId, pageNo: pageNo),
                  onBismillahLongPress: (surahId, pageNo) =>
                      _onBismillahLongPress(surahId, pageNo: pageNo),
                  onComputed: () {
                    if (pageNo < kMushafTotalPages) {
                      MushafLayout.prewarm(context, pageNo + 1);
                    }
                  },
                );
              },
            ),
          ),
          if (_resumeHint?.mode == ResumeHintMode.page)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 62,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: ResumeHintChip(hint: _resumeHint!),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single page pager item: chrome + one framed page body.
class MushafPage extends StatelessWidget {
  final int pageNo;
  final bool framed;
  final bool chromeVisible;
  final VoidCallback? onToggleChrome;
  final int? targetSurahId;
  final int? targetAyahNo;
  final int? selectedSurahId;
  final int? selectedAyahNo;
  final void Function(int surahId, int ayahNo, int pageNo)? onAyahTap;
  final void Function(int surahId, int ayahNo, int pageNo)? onAyahLongPress;
  final void Function(int surahId, int pageNo)? onBismillahTap;
  final void Function(int surahId, int pageNo)? onBismillahLongPress;
  final VoidCallback? onComputed;

  const MushafPage({
    super.key,
    required this.pageNo,
    this.framed = false,
    this.chromeVisible = true,
    this.onToggleChrome,
    this.targetSurahId,
    this.targetAyahNo,
    this.selectedSurahId,
    this.selectedAyahNo,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
    this.onComputed,
  });

  @override
  Widget build(BuildContext context) {
    if (framed) {
      return _MushafChrome(
        pageNumbers: [pageNo],
        framed: true,
        chromeVisible: chromeVisible,
        onToggleChrome: onToggleChrome,
        child: _MushafFramedBody(
          pages: [pageNo],
          bannerPageNo: pageNo,
          chromeVisible: chromeVisible,
          // Read above the chrome Scaffold, which strips the bottom padding.
          bottomInset: systemBottomInset(MediaQuery.of(context)),
          pageBody: (pageNo) => MushafPageBody(
            pageNo: pageNo,
            framed: true,
            targetSurahId: targetSurahId,
            targetAyahNo: targetAyahNo,
            selectedSurahId: selectedSurahId,
            selectedAyahNo: selectedAyahNo,
            showBanners: false,
            showBadge: false,
            onAyahTap: (surahId, ayahNo) =>
                onAyahTap?.call(surahId, ayahNo, pageNo),
            onAyahLongPress: (surahId, ayahNo) =>
                onAyahLongPress?.call(surahId, ayahNo, pageNo),
            onBismillahTap: (surahId) => onBismillahTap?.call(surahId, pageNo),
            onBismillahLongPress: (surahId) =>
                onBismillahLongPress?.call(surahId, pageNo),
            onComputed: onComputed,
          ),
        ),
      );
    }
    return _MushafChrome(
      pageNumbers: [pageNo],
      chromeVisible: chromeVisible,
      onToggleChrome: onToggleChrome,
      child: MushafPageBody(
        pageNo: pageNo,
        framed: framed,
        targetSurahId: targetSurahId,
        targetAyahNo: targetAyahNo,
        selectedSurahId: selectedSurahId,
        selectedAyahNo: selectedAyahNo,
        showBanners: !framed || chromeVisible,
        showBadge: chromeVisible,
        onAyahTap: (surahId, ayahNo) =>
            onAyahTap?.call(surahId, ayahNo, pageNo),
        onAyahLongPress: (surahId, ayahNo) =>
            onAyahLongPress?.call(surahId, ayahNo, pageNo),
        onBismillahTap: (surahId) => onBismillahTap?.call(surahId, pageNo),
        onBismillahLongPress: (surahId) =>
            onBismillahLongPress?.call(surahId, pageNo),
        onComputed: onComputed,
      ),
    );
  }
}

/// Two physical pages side by side: even on the left, odd on the right.
class _MushafSpread extends ConsumerWidget {
  const _MushafSpread({
    required this.leftPage,
    required this.rightPage,
    this.chromeVisible = true,
    this.onToggleChrome,
    this.targetSurahId,
    this.targetAyahNo,
    this.selectedSurahId,
    this.selectedAyahNo,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
    this.onComputed,
  });

  final int leftPage;
  final int rightPage;
  final bool chromeVisible;
  final VoidCallback? onToggleChrome;
  final int? targetSurahId;
  final int? targetAyahNo;
  final int? selectedSurahId;
  final int? selectedAyahNo;
  final void Function(int surahId, int ayahNo, int pageNo)? onAyahTap;
  final void Function(int surahId, int ayahNo, int pageNo)? onAyahLongPress;
  final void Function(int surahId, int pageNo)? onBismillahTap;
  final void Function(int surahId, int pageNo)? onBismillahLongPress;
  final VoidCallback? onComputed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget pageBody(int pageNo) {
      return MushafPageBody(
        pageNo: pageNo,
        framed: true,
        targetSurahId: targetSurahId,
        targetAyahNo: targetAyahNo,
        selectedSurahId: selectedSurahId,
        selectedAyahNo: selectedAyahNo,
        showBanners: false,
        showBadge: false,
        onAyahTap: (surahId, ayahNo) =>
            onAyahTap?.call(surahId, ayahNo, pageNo),
        onAyahLongPress: (surahId, ayahNo) =>
            onAyahLongPress?.call(surahId, ayahNo, pageNo),
        onBismillahTap: (surahId) => onBismillahTap?.call(surahId, pageNo),
        onBismillahLongPress: (surahId) =>
            onBismillahLongPress?.call(surahId, pageNo),
        onComputed: pageNo == rightPage ? onComputed : null,
      );
    }

    return _MushafChrome(
      pageNumbers: [rightPage, leftPage],
      framed: true,
      chromeVisible: chromeVisible,
      onToggleChrome: onToggleChrome,
      child: _MushafFramedBody(
        pages: [leftPage, rightPage],
        bannerPageNo: rightPage,
        chromeVisible: chromeVisible,
        // Read above the chrome Scaffold, which strips the bottom padding.
        bottomInset: systemBottomInset(MediaQuery.of(context)),
        pageBody: pageBody,
      ),
    );
  }
}

/// Height of the compact framed AppBar (no divider, no elevation).
const double _kFramedToolbarHeight = 44;

/// Normal mode: paper gap under the AppBar, matched above the nav bar.
const double _kFramedSheetGap = 4;

/// 1.0.23 AppBar: 54dp toolbar + 1dp divider.
const double _kLegacyBarHeight = 55;

/// 1.0.23 page badge block: 2 + 3 (ornament) + 8 + 44 (ring) + 4.
const double _kLegacyBadgeHeight = 61;

/// Banners + sheets for the framed (>= 600dp) reader, single page or spread.
///
/// In normal mode the area stops above the gesture/nav bar; in focus mode the
/// sheets get the full window. The 1.0.23 chrome this replaces is passed on as
/// the never-shrink floor for the text.
class _MushafFramedBody extends ConsumerWidget {
  const _MushafFramedBody({
    required this.pages,
    required this.bannerPageNo,
    required this.chromeVisible,
    required this.bottomInset,
    required this.pageBody,
  });

  /// Left to right.
  final List<int> pages;
  final int bannerPageNo;
  final bool chromeVisible;

  /// Gesture/nav bar height, kept clear while the bars are shown.
  final double bottomInset;
  final Widget Function(int pageNo) pageBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spread = pages.length == 2;
    final audioActive = ref.watch(
      audioPlayerProvider.select((s) => s.isActive),
    );
    final showBanners = chromeVisible && !audioActive;
    // 1.0.23: spread = top 6, banners, 8; single = top 20, hint banner, 12.
    final bannerTop = spread ? 6.0 : 20.0;
    final bannerGap = spread ? 8.0 : 12.0;
    final appLanguage = ref.watch(
      settingsProvider.select((s) => s.appLanguage),
    );

    // Normal mode only (focus pins its own decoration level): height the
    // 1.0.23 tree spent inside this area besides the 2dp + 2dp page body
    // padding that [mushafLegacyTextFrame] already removes.
    const taller = _kLegacyBarHeight - _kFramedToolbarHeight;
    // The top padding stayed when the banners were hidden by recitation.
    final top = showBanners ? 0.0 : bannerTop;
    final legacyChrome = spread
        // Badge, its 2dp bottom padding, the spread's 4dp bottom padding.
        ? taller + top + _kLegacyBadgeHeight + 2 + 4
        // Badge and 10dp bottom padding replaced the 2dp + 2dp body pads.
        : taller + top + _kLegacyBadgeHeight + 10 - 4;
    // The sheets' own top/bottom gap is part of the area 1.0.23 also had.
    final sheetGap = chromeVisible ? _kFramedSheetGap : 0.0;

    return Column(
      children: [
        if (showBanners)
          // Dismissed banners render nothing; their spacing goes with them,
          // so no empty strip sits between the AppBar and the sheets.
          _CollapsingPadding(
            padding: EdgeInsets.only(top: bannerTop, bottom: bannerGap),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MushafGestureHintBanner(),
                if (spread) MushafOfflineAudioBanner(pageNo: bannerPageNo),
              ],
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: sheetGap),
            child: MushafFramedSheets(
              pages: pages,
              focus: !chromeVisible,
              legacyVerticalChrome: legacyChrome - sheetGap * 2,
              pageBuilder: pageBody,
              pageNumberLabel: (pageNo) =>
                  AppLocalizations.getPageText(pageNo, appLanguage),
            ),
          ),
        ),
        SizedBox(height: chromeVisible ? bottomInset : 0),
      ],
    );
  }
}

/// Padding that disappears when its child lays out with zero height.
class _CollapsingPadding extends SingleChildRenderObjectWidget {
  const _CollapsingPadding({required this.padding, super.child});

  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCollapsingPadding(padding);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCollapsingPadding renderObject,
  ) {
    renderObject.padding = padding;
  }
}

class _RenderCollapsingPadding extends RenderShiftedBox {
  _RenderCollapsingPadding(this._padding) : super(null);

  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (value == _padding) return;
    _padding = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.deflate(_padding), parentUsesSize: true);
    final parentData = child.parentData! as BoxParentData;
    if (child.size.height <= 0) {
      parentData.offset = Offset.zero;
      size = constraints.constrain(Size(child.size.width, 0));
      return;
    }
    parentData.offset = Offset(_padding.left, _padding.top);
    size = constraints.constrain(Size(
      child.size.width + _padding.horizontal,
      child.size.height + _padding.vertical,
    ));
  }
}

/// Swipe-down-to-dismiss chrome shared by the single page and spread items.
class _MushafChrome extends StatefulWidget {
  const _MushafChrome({
    required this.pageNumbers,
    required this.child,
    this.framed = false,
    this.chromeVisible = true,
    this.onToggleChrome,
  });

  final List<int> pageNumbers;
  final Widget child;

  /// >= 600dp: compact one-line AppBar, the reclaimed height goes to the page.
  final bool framed;
  final bool chromeVisible;
  final VoidCallback? onToggleChrome;

  @override
  State<_MushafChrome> createState() => _MushafChromeState();
}

class _MushafChromeState extends State<_MushafChrome> {
  double _swipeStartY = 0.0;
  double _swipeStartX = 0.0;
  bool _isSwipingDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onVerticalDragStart: (details) {
        // Only detect swipe down from top area (AppBar region)
        if (details.globalPosition.dy < 100) {
          _swipeStartY = details.globalPosition.dy;
          _swipeStartX = details.globalPosition.dx;
          _isSwipingDown = false;
        }
      },
      onVerticalDragUpdate: (details) {
        if (_swipeStartY > 0) {
          final deltaY = details.globalPosition.dy - _swipeStartY;
          final deltaX = details.globalPosition.dx - _swipeStartX;
          if (deltaY > 20 && deltaY.abs() > deltaX.abs() * 1.5) {
            _isSwipingDown = true;
          }
        }
      },
      onVerticalDragEnd: (details) {
        if (_isSwipingDown && _swipeStartY > 0) {
          final deltaY = details.velocity.pixelsPerSecond.dy;
          final deltaX = details.velocity.pixelsPerSecond.dx;
          const swipeThreshold = 300.0;

          if (deltaY > swipeThreshold && deltaY.abs() > deltaX.abs()) {
            HapticFeedback.lightImpact();
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        }
        _swipeStartY = 0.0;
        _swipeStartX = 0.0;
        _isSwipingDown = false;
      },
      child: Scaffold(
        body: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: widget.chromeVisible
                  ? SizedBox(
                      key: const ValueKey<String>('mushaf-bar'),
                      height: (widget.framed
                              ? _kFramedToolbarHeight
                              : 55) +
                          MediaQuery.paddingOf(context).top,
                      child: widget.framed
                          ? _MushafFramedAppBar(
                              pageNumbers: widget.pageNumbers,
                            )
                          : _MushafAppBar(pageNumbers: widget.pageNumbers),
                    )
                  : const SizedBox(
                      key: ValueKey<String>('mushaf-no-bar'),
                      width: double.infinity,
                    ),
            ),
            Expanded(
              child: widget.onToggleChrome == null
                  ? widget.child
                  : GestureDetector(
                      // Taps on empty margins/gutter toggle the bars; taps on a
                      // glyph are claimed by the ayah recognizer and still play.
                      behavior: HitTestBehavior.translucent,
                      onTap: widget.onToggleChrome,
                      child: widget.child,
                    ),
            ),
          ],
        ),
        bottomNavigationBar: const GlobalRecitationBar(),
      ),
    );
  }
}

class _MushafAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _MushafAppBar({required this.pageNumbers});

  final List<int> pageNumbers;

  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final surahsAsync = ref.watch(surahNamesProvider);
    final isSpread = pageNumbers.length > 1;
    final firstPage = pageNumbers.first;
    final lastPage = pageNumbers.last;
    final pageTitle = isSpread
        ? AppLocalizations.getMushafSpreadPageText(
            firstPage,
            lastPage,
            appLanguage,
          )
        : AppLocalizations.getMushafPageText(firstPage, appLanguage);

    return AppBar(
      leading: ReaderBackButton.appBarLeading(context),
      automaticallyImplyLeading: false,
      toolbarHeight: 54,
      centerTitle: false,
      titleSpacing: 0,
      title: FutureBuilder<List<int>>(
        future: _surahIdsForPages(pageNumbers),
        builder: (context, surahIdsSnapshot) {
          return surahsAsync.when(
            data: (surahs) {
              final surahIds = surahIdsSnapshot.data ?? [];
              if (surahIds.isEmpty) {
                return ReaderAppBarTitleColumn(title: pageTitle);
              }

              final firstSurahId = surahIds.first;
              final lastSurahId = surahIds.last;

              final firstSurah = surahs.firstWhere(
                (s) => s.id == firstSurahId,
                orElse: () => SurahInfo(
                  id: firstSurahId,
                  arabicName: '',
                  englishName: 'Surah $firstSurahId',
                  englishMeaning: '',
                ),
              );

              final lastSurah = surahs.firstWhere(
                (s) => s.id == lastSurahId,
                orElse: () => SurahInfo(
                  id: lastSurahId,
                  arabicName: '',
                  englishName: 'Surah $lastSurahId',
                  englishMeaning: '',
                ),
              );

              final firstSurahName = _formatSurahName(firstSurah.englishName);
              final lastSurahName = _formatSurahName(lastSurah.englishName);
              final subtitle = surahIds.length == 1
                  ? AppLocalizations.formatMushafReaderSubtitle(
                      appLanguage,
                      firstSurahName,
                    )
                  : AppLocalizations.formatMushafReaderSubtitle(
                      appLanguage,
                      firstSurahName,
                      lastSurahName: lastSurahName,
                    );

              return ReaderAppBarTitleColumn(
                title: pageTitle,
                subtitle: subtitle,
              );
            },
            loading: () => ReaderAppBarTitleColumn(title: pageTitle),
            error: (_, __) => ReaderAppBarTitleColumn(title: pageTitle),
          );
        },
      ),
      actions: const [
        _MushafTextSettingsAction(),
      ],
      bottom: readerAppBarBottomDivider(colorScheme),
    );
  }
}

/// Compact framed AppBar: back, "Mushaf · Halaman 603–604", muted "Juz 30", Tt.
class _MushafFramedAppBar extends ConsumerWidget {
  const _MushafFramedAppBar({required this.pageNumbers});

  /// Ascending ([rightPage, leftPage] for a spread).
  final List<int> pageNumbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appLanguage = ref.watch(
      settingsProvider.select((s) => s.appLanguage),
    );
    final first = pageNumbers.first;
    final last = pageNumbers.last;
    final db = ref.watch(databaseProvider);

    return AppBar(
      leading: ReaderBackButton.appBarLeading(context),
      automaticallyImplyLeading: false,
      toolbarHeight: _kFramedToolbarHeight,
      centerTitle: false,
      titleSpacing: 0,
      title: Row(
        children: [
          Flexible(
            child: Text(
              AppLocalizations.getMushafFramedTitle(first, last, appLanguage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FutureBuilder<(int, int)?>(
            future: _juzRangeForPages(db, first, last),
            builder: (context, snapshot) {
              final juz = snapshot.data;
              if (juz == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: Text(
                  AppLocalizations.formatMushafJuzLabel(
                    juz.$1,
                    juz.$2,
                    appLanguage,
                  ),
                  maxLines: 1,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: const [
        _MushafTextSettingsAction(),
      ],
      // Framed mode: no divider or elevation; the paper starts right below.
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }
}

Future<(int, int)?> _juzRangeForPages(
  AppDatabase db,
  int firstPage,
  int lastPage,
) async {
  try {
    final firstVerses = await db.getVersesByPage(firstPage);
    final lastVerses = firstPage == lastPage
        ? firstVerses
        : await db.getVersesByPage(lastPage);
    if (firstVerses.isEmpty || lastVerses.isEmpty) return null;
    return (firstVerses.first.juz, lastVerses.last.juz);
  } catch (_) {
    return null;
  }
}

/// AppBar "Tt" entry that opens the Mushaf text settings sheet.
///
/// Shown for legacy Mushaf, when the glyph slider flag is on, or when the window
/// can show a spread (so the two-page toggle stays reachable).
class _MushafTextSettingsAction extends StatefulWidget {
  const _MushafTextSettingsAction();

  @override
  State<_MushafTextSettingsAction> createState() =>
      _MushafTextSettingsActionState();
}

class _MushafTextSettingsActionState extends State<_MushafTextSettingsAction> {
  Future<bool>? _visibleFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibleFuture ??= isMushafTextSettingsAppBarVisible(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _visibleFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        final appLanguage = ProviderScope.containerOf(context, listen: false)
            .read(settingsProvider)
            .appLanguage;
        return IconButton(
          icon: const Icon(Icons.text_fields),
          tooltip: AppLocalizations.getSettingsText(
            'text_settings_title',
            appLanguage,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const MushafTextSettingsDialog(),
            );
          },
        );
      },
    );
  }
}

Future<List<int>> _surahIdsForPages(List<int> pageNumbers) async {
  final ids = <int>[];
  for (final pageNo in pageNumbers) {
    final pageIds = await MushafLayout.getSurahIdsForPage(pageNo);
    for (final id in pageIds) {
      if (!ids.contains(id)) ids.add(id);
    }
  }
  return ids;
}

String _formatSurahName(String name) {
  final formattedNames = {
    'Al-Fatiha': 'Al-Fātiḥah',
    'Al-Baqarah': 'Al-Baqarah',
    'Ali Imran': 'Āl ʿImrān',
    'An-Nisa': 'An-Nisāʾ',
    'Al-Maidah': 'Al-Māʾidah',
    "Al-An'am": 'Al-Anʿām',
    "Al-A'raf": 'Al-Aʿrāf',
    'Al-Anfal': 'Al-Anfāl',
    'At-Tawbah': 'At-Tawbah',
    "Ar-Ra'd": 'Ar-Raʿd',
    'Al-Hijr': 'Al-Ḥijr',
    "Al-Isra'": 'Al-Isrāʾ',
    'Al-Kahf': 'Al-Kahf',
    'Al-Anbiya': 'Al-Anbiyāʾ',
    "Al-Mu'minun": 'Al-Muʾminūn',
    "Ash-Shu'ara": 'Ash-Shuʿarāʾ',
    "Al-'Ankabut": 'Al-ʿAnkabūt',
    "Al-Jumu'ah": 'Al-Jumuʿah',
    "Al-Ma'arij": 'Al-Maʿārij',
    "Al-A'la": 'Al-Aʿlā',
  };
  return formattedNames[name] ?? name;
}

class _MushafPageSnapshot {
  const _MushafPageSnapshot.glyph(
    this.glyphContent, {
    this.openingScale = 1.0,
  }) : legacyBlocks = null;

  const _MushafPageSnapshot.legacy(this.legacyBlocks)
      : glyphContent = null,
        openingScale = 1.0;

  final QpcV2PageContent? glyphContent;
  final List<MushafAyahBlock>? legacyBlocks;

  /// Opening pages 1-2 share one enlarged scale; 1 for all other pages.
  final double openingScale;

  bool get isGlyph => glyphContent != null;
}

/// Page content (glyph or legacy) without app chrome.
///
/// Lives inside a [MushafPageFrame] when [framed] is set by the caller, so
/// a page renders identically in single mode and in a spread.
class MushafPageBody extends ConsumerStatefulWidget {
  const MushafPageBody({
    super.key,
    required this.pageNo,
    this.framed = false,
    this.targetSurahId,
    this.targetAyahNo,
    this.selectedSurahId,
    this.selectedAyahNo,
    this.showBanners = true,
    this.showBadge = true,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
    this.onComputed,
  });

  final int pageNo;
  final bool framed;
  final int? targetSurahId;
  final int? targetAyahNo;
  final int? selectedSurahId;
  final int? selectedAyahNo;
  final bool showBanners;
  final bool showBadge;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onComputed;

  @override
  ConsumerState<MushafPageBody> createState() => _MushafPageBodyState();
}

class _MushafPageBodyState extends ConsumerState<MushafPageBody> {
  late Future<_MushafPageSnapshot> _pageFuture;
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _ayahKeys = {};
  bool _hasScrolledToTarget = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshLines();
    _setupScrollListener();
  }

  void _refreshLines() {
    _pageFuture = _loadPage();
  }

  Future<_MushafPageSnapshot> _loadPage() async {
    if (await QpcV2MushafLayout.isAvailable()) {
      await MushafWarmup.ensureInitialized();
      final layout = QpcV2MushafLayout(QpcV2MushafLayout.sharedRepository());
      final content = await layout.getPageContent(widget.pageNo);
      var openingScale = 1.0;
      if (widget.pageNo <= 2) {
        // Pages 1-2 share one scale, computed from both pages.
        final sibling = await layout.getPageContent(
          widget.pageNo == 1 ? 2 : 1,
        );
        final glyphLines = [content, sibling].expand(
          (page) => page.lines
              .where((line) => line.isAyah && line.glyphText.isNotEmpty)
              .map((line) => (
                    glyphText: line.glyphText,
                    fontFamily: page.fontFamily,
                    justify: false,
                  )),
        );
        openingScale = computeOpeningPageScale(lines: glyphLines);
      }
      return _MushafPageSnapshot.glyph(
        content,
        openingScale: openingScale,
      );
    }
    if (!mounted) {
      return const _MushafPageSnapshot.legacy([]);
    }
    final blocks = await MushafLayout.getPageBlocks(context, widget.pageNo);
    return _MushafPageSnapshot.legacy(blocks);
  }

  void _setupScrollListener() {
    _scrollController.addListener(_onScrollChanged);
  }

  void _onScrollChanged() {
    if (!mounted) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _updateLastRead();
    });
  }

  void _updateLastRead() {
    if (!mounted) return;
    
    _pageFuture.then((snapshot) {
      if (!mounted) return;
      if (snapshot.isGlyph) {
        for (final line in snapshot.glyphContent!.lines) {
          if (!line.isAyah || line.words.isEmpty) continue;
          final word = line.words.first;
          final source = PageSource(widget.pageNo);
          ref.read(lastReadProvider.notifier).saveLastRead(
            source,
            ayahNo: word.ayah,
            surahId: word.surah,
          );
          logReadingActivityDay();
          return;
        }
        return;
      }

      final blocks = snapshot.legacyBlocks ?? [];
      if (blocks.isEmpty) return;
      
      // Find the first visible ayah by checking scroll position
      // This is approximate - for exact tracking, we'd need to measure widget positions
      // Simple heuristic: find ayah that should be visible based on scroll
      // For more accuracy, we'd need to use RenderBox to measure actual positions
      MushafAyahBlock? visibleBlock;
      for (final block in blocks) {
        if (block.surahId != null && block.ayahNo != null) {
          visibleBlock = block;
          break; // Use first ayah as approximation
        }
      }
      
      if (visibleBlock?.surahId != null && visibleBlock?.ayahNo != null) {
        final source = PageSource(widget.pageNo);
        ref.read(lastReadProvider.notifier).saveLastRead(
          source,
          ayahNo: visibleBlock!.ayahNo,
          surahId: visibleBlock.surahId,
        );
        logReadingActivityDay();
      }
    });
  }

  void _scrollToTargetAyah() {
    if (_hasScrolledToTarget) return;
    if (widget.targetSurahId == null || widget.targetAyahNo == null) return;
    
    final key = '${widget.targetSurahId}_${widget.targetAyahNo}';
    final targetKey = _ayahKeys[key];
    
    if (targetKey?.currentContext == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasScrolledToTarget) return;
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _hasScrolledToTarget) return;
        
        try {
          final context = targetKey!.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
            
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                _hasScrolledToTarget = true;
              }
            });
          }
        } catch (e) {
          if (mounted) {
            _hasScrolledToTarget = true;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MushafPageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNo != widget.pageNo) {
      _refreshLines();
      _hasScrolledToTarget = false;
      _ayahKeys.clear();
    } else if (oldWidget.targetSurahId != widget.targetSurahId ||
        oldWidget.targetAyahNo != widget.targetAyahNo) {
      _hasScrolledToTarget = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final fontSize = settings.mushafFontSize;

    return FutureBuilder<_MushafPageSnapshot>(
      future: _pageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final pageData = snapshot.data;
        if (pageData == null) {
          return const Center(child: Text('Error: empty page'));
        }
        widget.onComputed?.call();

        // Scroll to target ayah if needed (framed pages are fully visible).
        if (!widget.framed &&
            widget.targetSurahId != null &&
            widget.targetAyahNo != null &&
            !_hasScrolledToTarget) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasScrolledToTarget) {
              _scrollToTargetAyah();
            }
          });
        }

        final audio = ref.watch(audioPlayerProvider);
        final bottomInset = systemBottomInset(MediaQuery.of(context));

        final pageContent = Column(
          children: [
            if (widget.showBanners && !audio.isActive) ...[
              const MushafGestureHintBanner(),
              MushafOfflineAudioBanner(pageNo: widget.pageNo),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _MushafPageContent(
                pageData: pageData,
                pageNo: widget.pageNo,
                framed: widget.framed,
                fontSize: fontSize,
                colorScheme: colorScheme,
                ayahKeys: _ayahKeys,
                scrollController: _scrollController,
                selectedSurahId: widget.selectedSurahId,
                selectedAyahNo: widget.selectedAyahNo,
                targetSurahId: widget.targetSurahId,
                targetAyahNo: widget.targetAyahNo,
                onAyahTap: widget.onAyahTap,
                onAyahLongPress: widget.onAyahLongPress,
                onBismillahTap: widget.onBismillahTap,
                onBismillahLongPress: widget.onBismillahLongPress,
                onScrollToTarget: _scrollToTargetAyah,
              ),
            ),
            if (widget.showBadge)
              Center(
                child: MushafPageNumberBadge(pageNo: widget.pageNo),
              ),
          ],
        );

        if (widget.framed && pageData.isGlyph) {
          // Placed by [MushafFramedSheets]: exactly the scaled text box.
          return MushafPageSheet(
            content: pageData.glyphContent!,
            openingPageScale: pageData.openingScale,
            colorScheme: colorScheme,
            ayahKeys: _ayahKeys,
            onAyahTap: widget.onAyahTap,
            onAyahLongPress: widget.onAyahLongPress,
            onBismillahTap: widget.onBismillahTap,
            onBismillahLongPress: widget.onBismillahLongPress,
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 32 + bottomInset),
          child: pageContent,
        );
      },
    );
  }
}

/// Glyph or legacy page content, shared by single page and spread modes.
class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.pageData,
    required this.pageNo,
    required this.framed,
    required this.fontSize,
    required this.colorScheme,
    required this.ayahKeys,
    required this.scrollController,
    required this.selectedSurahId,
    required this.selectedAyahNo,
    required this.targetSurahId,
    required this.targetAyahNo,
    required this.onAyahTap,
    required this.onAyahLongPress,
    required this.onBismillahTap,
    required this.onBismillahLongPress,
    required this.onScrollToTarget,
  });

  final _MushafPageSnapshot pageData;
  final int pageNo;
  final bool framed;
  final double fontSize;
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;
  final ScrollController scrollController;
  final int? selectedSurahId;
  final int? selectedAyahNo;
  final int? targetSurahId;
  final int? targetAyahNo;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback onScrollToTarget;

  @override
  Widget build(BuildContext context) {
    if (!pageData.isGlyph) {
      return SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            _FlowingMushafText(
              blocks: pageData.legacyBlocks ?? [],
              fontSize: fontSize,
              colorScheme: colorScheme,
              ayahKeys: ayahKeys,
              selectedSurahId: selectedSurahId,
              selectedAyahNo: selectedAyahNo,
              onAyahTap: onAyahTap,
              onAyahLongPress: onAyahLongPress,
              onBismillahTap: onBismillahTap,
              onBismillahLongPress: onBismillahLongPress,
              onAyahKeyCreated: () {
                if (targetSurahId != null && targetAyahNo != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onScrollToTarget();
                  });
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }
    // Frame mode is handled by the caller (fixed reference box + uniform scale).
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return QpcV2MushafText(
                content: pageData.glyphContent!,
                contentWidth: constraints.maxWidth,
                fontSize: fontSize,
                colorScheme: colorScheme,
                ayahKeys: ayahKeys,
                onAyahTap: onAyahTap,
                onAyahLongPress: onAyahLongPress,
                onBismillahTap: onBismillahTap,
                onBismillahLongPress: onBismillahLongPress,
                onAyahKeyCreated: () {
                  if (targetSurahId != null && targetAyahNo != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onScrollToTarget();
                    });
                  }
                },
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Outer gap around surah name; matches [SurahNameMushafGlyph] vertical pad (10).
const _mushafSurahNameOuterGap = 12.0;

/// Top inset when a surah title follows ayat on the same page (same visual gap as name→Bismillah).
const _mushafSurahNameAfterAyahTop = 24.0;

/// Widget untuk menampilkan teks mushaf yang mengalir
class _FlowingMushafText extends ConsumerWidget {
  final List<MushafAyahBlock> blocks;
  final double fontSize;
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;
  final int? selectedSurahId;
  final int? selectedAyahNo;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onAyahKeyCreated;

  const _FlowingMushafText({
    required this.blocks,
    required this.fontSize,
    required this.colorScheme,
    required this.ayahKeys,
    this.selectedSurahId,
    this.selectedAyahNo,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
    this.onAyahKeyCreated,
  });

  /// Open bottom sheet for ayah: translation (Meaning) + Share, Bookmark, Copy (Nusuk-style)
  static void showAyahSheet(BuildContext context, WidgetRef ref, int surahId, int ayahNo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _MushafAyahSheet(
        surahId: surahId,
        ayahNo: ayahNo,
        ref: ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);

    final List<Widget> children = [];
    final List<InlineSpan> currentSpans = [];
    final List<GestureRecognizer> recognizers = []; // Track recognizers for disposal

    void flushCurrentSpans() {
      if (currentSpans.isNotEmpty) {
        children.add(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(children: List.from(currentSpans)),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              textWidthBasis: TextWidthBasis.longestLine, // Justifikasi yang lebih baik
              style: TextStyle(
                fontFamily: 'UthmanicHafsV22',
                fontFamilyFallback: const ['UthmanicHafs'],
                fontSize: fontSize,
                height: 1.6, // Line height lebih compact (seperti mushaf fisik)
                color: colorScheme.onSurface,
                letterSpacing: 0.0, // No letter spacing untuk compact display
                wordSpacing: 0.0, // No word spacing untuk compact display
              ),
            ),
          ),
        );
        currentSpans.clear();
      }
    }

    for (final block in blocks) {
      if (block.isSurahHeader) {
        flushCurrentSpans();

        final surahId = block.surahId;
        final followsAyahOnPage = children.isNotEmpty;
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: followsAyahOnPage
                  ? _mushafSurahNameAfterAyahTop
                  : _mushafSurahNameOuterGap,
              bottom: _mushafSurahNameOuterGap,
            ),
            child: SizedBox(
              width: double.infinity,
              child: surahId != null
                  ? SurahNameMushafGlyph(
                      surahId: surahId,
                      mushafFontSize: fontSize,
                    )
                  : Text(
                      block.text,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'UthmanicHafsV22',
                        fontFamilyFallback: const ['UthmanicHafs'],
                        fontSize: fontSize + 4,
                        fontWeight: FontWeight.w600,
                        height: 1.7,
                        color: colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
        );
        continue;
      }

      if (block.isBismillah) {
        flushCurrentSpans();

        final isRecitingBismillah = audio.isPlayingBismillah &&
            block.surahId != null &&
            block.surahId == audio.surahId;
        final bismillahBg = isRecitingBismillah
            ? colorScheme.primary.withValues(alpha: 0.14)
            : null;

        GestureRecognizer? bismillahTap;
        if (block.surahId != null) {
          bismillahTap = _TapAndLongPressRecognizer(
            onTap: () {
              HapticFeedback.selectionClick();
              onBismillahTap?.call(block.surahId!);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              onBismillahLongPress?.call(block.surahId!);
            },
          );
          recognizers.add(bismillahTap);
        }

        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text.rich(
                TextSpan(
                  text: block.text,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafsV22',
                    fontFamilyFallback: const ['UthmanicHafs'],
                    fontSize: fontSize - 2,
                    height: 1.7,
                    color: colorScheme.onSurface,
                    backgroundColor: bismillahBg,
                  ),
                  recognizer: bismillahTap,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        continue;
      }

      // Create key for this ayah if it has surahId and ayahNo
      GlobalKey? ayahKey;
      if (block.surahId != null && block.ayahNo != null) {
        final key = '${block.surahId}_${block.ayahNo}';
        if (!ayahKeys.containsKey(key)) {
          ayahKey = GlobalKey();
          ayahKeys[key] = ayahKey;
        } else {
          ayahKey = ayahKeys[key];
        }
      }

      // Tap on ayah: light tint; recitation uses a rounded frame (not per-word boxes).
      final recitingAyahNo = audio.isPlayingBismillah
          ? Bismillah.audioAyahNo
          : audio.ayahNo;
      final isRecitingAyah = block.isBismillah
          ? recitingAyahNo == Bismillah.audioAyahNo &&
              block.surahId != null &&
              block.surahId == audio.surahId
          : audio.surahId != null &&
              block.surahId == audio.surahId &&
              block.ayahNo != null &&
              block.ayahNo == recitingAyahNo;
      final isSelected = audio.isActive &&
          block.surahId == audio.surahId &&
          block.ayahNo != null &&
          block.ayahNo == recitingAyahNo;
      final recitationHighlight = isRecitingAyah || isSelected
          ? colorScheme.primary.withValues(alpha: 0.14)
          : null;

      GestureRecognizer? recognizer;
      if (block.surahId != null && block.ayahNo != null) {
        recognizer = _TapAndLongPressRecognizer(
          onTap: () {
            HapticFeedback.selectionClick();
            onAyahTap?.call(block.surahId!, block.ayahNo!);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onAyahLongPress?.call(block.surahId!, block.ayahNo!);
          },
        );
        recognizers.add(recognizer);
      }

      final ayahSpans = <InlineSpan>[];
      ayahSpans.add(
        TextSpan(
          text: block.text,
          style: TextStyle(
            fontFamily: 'UthmanicHafsV22',
            fontFamilyFallback: const ['UthmanicHafs'],
            fontSize: fontSize,
            color: colorScheme.onSurface,
            backgroundColor: recitationHighlight,
          ),
          recognizer: recognizer,
        ),
      );

      if (block.ayahNo != null) {
        ayahSpans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
            child: KeyedSubtree(
              key: ayahKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _InlineAyahNumber(
                  ayahNo: block.ayahNo!,
                  fontSize: fontSize,
                  colorScheme: colorScheme,
                  surahId: block.surahId,
                  isReciting: isRecitingAyah,
                ),
              ),
            ),
          ),
        );
      }

      ayahSpans.add(
        TextSpan(
          text: ' ',
          style: TextStyle(fontSize: fontSize * 0.2),
        ),
      );

      currentSpans.addAll(ayahSpans);
    }

    flushCurrentSpans();
    
    // Call callback after keys are created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onAyahKeyCreated?.call();
    });

    // Dispose recognizers when widget is disposed
    // Note: Recognizers will be disposed automatically when TextSpan is disposed
    // But we keep the list for reference if needed

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

}

/// Widget untuk nomor ayat inline dengan bookmark support
class _InlineAyahNumber extends ConsumerStatefulWidget {
  final int ayahNo;
  final double fontSize;
  final ColorScheme colorScheme;
  final int? surahId;
  final bool isReciting;

  const _InlineAyahNumber({
    required this.ayahNo,
    required this.fontSize,
    required this.colorScheme,
    this.surahId,
    this.isReciting = false,
  });

  @override
  ConsumerState<_InlineAyahNumber> createState() => _InlineAyahNumberState();
}

class _InlineAyahNumberState extends ConsumerState<_InlineAyahNumber> {
  bool _isBookmarked = false;
  bool _isCheckingBookmark = true;

  @override
  void initState() {
    super.initState();
    if (widget.surahId != null) {
      _checkBookmark();
    } else {
      _isCheckingBookmark = false;
    }
  }

  Future<void> _checkBookmark() async {
    if (widget.surahId == null) {
      setState(() {
        _isCheckingBookmark = false;
      });
      return;
    }

    final bookmarked = await isBookmarked(
      ref,
      widget.surahId!,
      widget.ayahNo,
    );
    
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
        _isCheckingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.surahId == null) return;
    
    await toggleBookmark(
      ref,
      widget.surahId!,
      widget.ayahNo,
      openContext: BookmarkOpenContext.mushaf,
    );
    
    await _checkBookmark();
  }

  @override
  Widget build(BuildContext context) {
    final displayNumber = MushafLayout.toArabicIndicDigits(widget.ayahNo.toString());
    
    // Listen to bookmark refresh
    ref.listen(bookmarkRefreshProvider, (previous, next) {
      if (previous != next && widget.surahId != null) {
        _checkBookmark();
      }
    });
    
    final reciting = widget.isReciting;
    final borderColor = _isBookmarked
        ? widget.colorScheme.primary
        : widget.colorScheme.outline.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: widget.surahId != null && !_isCheckingBookmark ? _toggleBookmark : null,
      child: Container(
        padding: EdgeInsets.all(widget.fontSize * 0.2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: _isBookmarked ? 2.0 : 1.5,
          ),
          color: reciting
              ? widget.colorScheme.primary.withValues(alpha: 0.12)
              : _isBookmarked
                  ? widget.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
        ),
        child: Text(
          displayNumber,
          style: TextStyle(
            fontSize: widget.fontSize * 1.0,
            fontFamily: 'UthmanicHafsV22',
            fontFamilyFallback: const ['UthmanicHafs'],
            color: reciting || _isBookmarked
                ? widget.colorScheme.primary
                : widget.colorScheme.onSurface,
            height: 1.0,
            fontWeight: reciting || _isBookmarked ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Nusuk-style bottom sheet: Meaning (translation) + Share, Bookmark, Copy
class _MushafAyahSheet extends ConsumerStatefulWidget {
  final int surahId;
  final int ayahNo;
  final WidgetRef ref;

  const _MushafAyahSheet({
    required this.surahId,
    required this.ayahNo,
    required this.ref,
  });

  @override
  ConsumerState<_MushafAyahSheet> createState() => _MushafAyahSheetState();
}

class _MushafAyahSheetState extends ConsumerState<_MushafAyahSheet> {
  bool? _bookmarked;
  bool _bookmarkLoadStarted = false;

  Future<void> _loadBookmark() async {
    final b = await isBookmarked(ref, widget.surahId, widget.ayahNo);
    if (mounted) setState(() => _bookmarked = b);
  }

  static String? _getTranslation(Verse verse, String lang) {
    final raw = switch (lang) {
      'en' => verse.trEn,
      'id' => verse.trId,
      'zh' => verse.trZh,
      'ja' => verse.trJa,
      _ => verse.trId,
    };
    return raw != null ? TranslationCleaner.clean(raw) : null;
  }

  Future<void> _shareVerse(Verse verse, AppSettings settings) async {
    final surahs = ref.read(surahNamesProvider).valueOrNull;
    final surahName = surahs != null
        ? surahs
            .firstWhere(
              (s) => s.id == verse.surahId,
              orElse: () => surahs.first,
            )
            .englishName
        : 'Surah ${verse.surahId}';

    await VerseShare.share(
      context: context,
      ref: ref,
      verse: verse,
      surahName: surahName,
      settings: settings,
    );
  }

  Future<void> _copyVerse(Verse verse, AppSettings settings) async {
    final translation = _getTranslation(verse, settings.language);
    final surahs = ref.read(surahNamesProvider).valueOrNull;
    final surahName = surahs != null
        ? surahs.firstWhere(
            (s) => s.id == verse.surahId,
            orElse: () => surahs.first,
          ).englishName
        : 'Surah ${verse.surahId}';
    final buffer = StringBuffer();
    buffer.writeln(verse.arabic);
    buffer.writeln('');
    if (translation != null) buffer.writeln(translation);
    buffer.writeln('');
    buffer.writeln('QS. $surahName ${verse.surahId}:${verse.ayahNo}');
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final db = ref.read(databaseProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return FutureBuilder<Verse?>(
          future: db.getVerse(widget.surahId, widget.ayahNo),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : const Text('Verse not found'),
                ),
              );
            }
            final verse = snapshot.data!;
            if (!_bookmarkLoadStarted) {
              _bookmarkLoadStarted = true;
              _loadBookmark();
            }

            final translation = _getTranslation(verse, settings.language);

            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final audio = ref.watch(audioPlayerProvider);
                          final isCurrent = audio.surahId == widget.surahId &&
                              audio.ayahNo == widget.ayahNo;
                          final isPlayingThis = isCurrent && audio.isPlaying;
                          return IconButton.filled(
                            onPressed: () {
                              if (isCurrent) {
                                final notifier =
                                    ref.read(audioPlayerProvider.notifier);
                                if (audio.isPlaying) {
                                  notifier.pause();
                                } else {
                                  notifier.restart();
                                }
                              } else {
                                final surahs = ref.read(surahNamesProvider).valueOrNull;
                                final surahName = surahs
                                    ?.firstWhere(
                                      (s) => s.id == widget.surahId,
                                      orElse: () => surahs.first,
                                    )
                                    .englishName;
                                PlaybackActions.playMushafAyah(
                                  context,
                                  ref,
                                  widget.surahId,
                                  widget.ayahNo,
                                  surahName: surahName,
                                );
                              }
                            },
                            icon: Icon(
                              isPlayingThis ? Icons.pause : Icons.play_arrow,
                              size: 22,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => _shareVerse(verse, settings),
                        icon: const Icon(Icons.share_outlined, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () async {
                          await toggleBookmark(
                            ref,
                            widget.surahId,
                            widget.ayahNo,
                            openContext: BookmarkOpenContext.mushaf,
                          );
                          await _loadBookmark();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_bookmarked == true
                                    ? 'Ayat ${widget.ayahNo} di-bookmark'
                                    : 'Bookmark ayat ${widget.ayahNo} dihapus'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          _bookmarked == true ? Icons.bookmark : Icons.bookmark_outline,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _bookmarked == true
                              ? colorScheme.primary
                              : colorScheme.primaryContainer,
                          foregroundColor: _bookmarked == true
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => _copyVerse(verse, settings),
                        icon: const Icon(Icons.copy_rounded, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () {
                          showFeedbackForm(
                            context,
                            type: FeedbackType.bug,
                            language: settings.appLanguage,
                            contextData: FeedbackContext(
                              surahId: widget.surahId,
                              ayahNo: widget.ayahNo,
                              arabicSnippet: verse.arabic,
                            ),
                          );
                        },
                        icon: const Icon(Icons.flag_outlined, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.getMeaningLabel(settings.appLanguage),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translation ?? '—',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Lets a single [TextSpan] respond to BOTH tap and long-press.
///
/// A [TextSpan] accepts only one recognizer, so attaching a separate
/// [TapGestureRecognizer] and [LongPressGestureRecognizer] would drop one of
/// them (previously the long-press, so long-pressing an ayah just played it).
/// This forwards each pointer to two internal recognizers that compete in the
/// gesture arena: a quick release fires [onTap], a held press fires
/// [onLongPress].
class _TapAndLongPressRecognizer extends GestureRecognizer {
  _TapAndLongPressRecognizer({VoidCallback? onTap, VoidCallback? onLongPress}) {
    _tap = TapGestureRecognizer(debugOwner: this)..onTap = onTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = onLongPress;
  }

  late final TapGestureRecognizer _tap;
  late final LongPressGestureRecognizer _longPress;

  @override
  void addPointer(PointerDownEvent event) {
    _tap.addPointer(event);
    _longPress.addPointer(event);
  }

  @override
  String get debugDescription => 'tapAndLongPress';

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}

  @override
  void addAllowedPointer(PointerDownEvent event) {}

  @override
  void dispose() {
    _tap.dispose();
    _longPress.dispose();
    super.dispose();
  }
}


