import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/share/verse_share.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/mushaf_navigation_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/models/bookmark_open_context.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/core/tajweed/tajweed_parser.dart';
import 'package:quran_offline/core/feedback/feedback_context.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/features/settings/feedback_form_sheet.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';
import 'package:quran_offline/features/audio/global_recitation_bar.dart';
import 'package:quran_offline/features/read/widgets/mushaf_offline_audio_banner.dart';
import 'package:quran_offline/features/read/widgets/mushaf_gesture_hint_banner.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_number_badge.dart';
import 'package:quran_offline/features/read/widgets/mushaf_text_settings_dialog.dart';
import 'package:quran_offline/features/reader/widgets/reader_app_bar.dart';
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
  int? _selectedSurahId;
  int? _selectedAyahNo;
  late int _visiblePageNo;
  int? _scrollToSurahId;
  int? _scrollToAyahNo;
  bool _programmaticPageChange = false;

  @override
  void initState() {
    super.initState();
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
      ref.read(mushafSessionActiveProvider.notifier).state = true;
      ref.read(mushafVisiblePageProvider.notifier).state = _visiblePageNo;
      MushafWarmup.beginSession(priorityPage: widget.initialPage);
      unawaited(
        MushafLayout.prewarmNeighbors(context, widget.initialPage),
      );
    });
  }

  void _onPageControllerTick() {
    if (!_controller.hasClients) return;
    final page = _controller.page;
    if (page == null) return;
    MushafWarmup.prefetchDuringSwipe(page);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageControllerTick);
    _controller.dispose();
    super.dispose();
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

    if (pageNo == _visiblePageNo) return;

    _programmaticPageChange = true;
    _visiblePageNo = pageNo;
    ref.read(mushafVisiblePageProvider.notifier).state = pageNo;

    await _controller.animateToPage(
      pageNo - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _syncPageToRecitation(AudioPlayerState audio) async {
    if (!audio.isActive || audio.surahId == null || audio.ayahNo == null) {
      return;
    }

    final surahId = audio.surahId!;
    final ayahNo = audio.ayahNo!;

    final onPage = await MushafLayout.pageContainsRecitation(
      _visiblePageNo,
      surahId,
      ayahNo,
    );
    if (!mounted || onPage) return;

    final db = ref.read(databaseProvider);
    final lookupAyah = ayahNo == Bismillah.audioAyahNo ? 1 : ayahNo;
    final pageNo = await db.getPageForAyah(surahId, lookupAyah);
    if (!mounted || pageNo == null) return;

    final scrollAyah =
        audio.isPlayingBismillah ? Bismillah.audioAyahNo : ayahNo;
    await _goToPage(pageNo, surahId: surahId, ayahNo: scrollAyah);
  }

  void _onAyahTap(int surahId, int ayahNo) {
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
    PlaybackActions.playMushafAyah(
      context,
      ref,
      surahId,
      ayahNo,
      surahName: surahName,
    );
  }

  void _onBismillahTap(int surahId) {
    _onAyahTap(surahId, Bismillah.audioAyahNo);
  }

  void _onBismillahLongPress(int surahId) {
    _onAyahLongPress(surahId, Bismillah.audioAyahNo);
  }

  void _onAyahLongPress(int surahId, int ayahNo) {
    setState(() {
      _selectedSurahId = surahId;
      _selectedAyahNo = ayahNo;
    });
    _FlowingMushafText.showAyahSheet(context, ref, surahId, ayahNo);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((s) => s.mushafFontSize));

    ref.listen<AudioPlayerState>(audioPlayerProvider, (previous, next) {
      if (!mounted) return;
      if (!next.isActive) {
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
      child: PageView.builder(
      controller: _controller,
      reverse: true, // RTL direction: swipe right-to-left = next page (index increases)
      onPageChanged: (index) {
        final pageNo = index + 1;
        _visiblePageNo = pageNo;
        ref.read(mushafVisiblePageProvider.notifier).state = pageNo;
        MushafLayout.prewarmNeighbors(context, pageNo);
        if (_programmaticPageChange) {
          _programmaticPageChange = false;
        } else {
          setState(() {
            _scrollToSurahId = null;
            _scrollToAyahNo = null;
            _selectedSurahId = null;
            _selectedAyahNo = null;
          });
        }
      },
      itemCount: 604,
      itemBuilder: (context, index) {
        // Normal mapping: index 0 = page 1, index 603 = page 604
        // With reverse: true, index 0 starts on the right, index 603 on the left
        final pageNo = index + 1;
        return MushafPage(
          pageNo: pageNo,
          targetSurahId: _scrollToSurahId,
          targetAyahNo: _scrollToAyahNo,
          selectedSurahId: _selectedSurahId,
          selectedAyahNo: _selectedAyahNo,
          onAyahTap: _onAyahTap,
          onAyahLongPress: _onAyahLongPress,
          onBismillahTap: _onBismillahTap,
          onBismillahLongPress: _onBismillahLongPress,
          onComputed: () {
            if (pageNo < 604) {
              MushafLayout.prewarm(context, pageNo + 1);
            }
          },
        );
      },
      ),
    );
  }
}

class MushafPage extends ConsumerStatefulWidget {
  final int pageNo;
  final int? targetSurahId;
  final int? targetAyahNo;
  final int? selectedSurahId;
  final int? selectedAyahNo;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onComputed;

  const MushafPage({
    super.key,
    required this.pageNo,
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
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageSnapshot {
  const _MushafPageSnapshot.glyph(this.glyphContent) : legacyBlocks = null;

  const _MushafPageSnapshot.legacy(this.legacyBlocks) : glyphContent = null;

  final QpcV2PageContent? glyphContent;
  final List<MushafAyahBlock>? legacyBlocks;

  bool get isGlyph => glyphContent != null;
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late Future<_MushafPageSnapshot> _pageFuture;
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _ayahKeys = {};
  bool _hasScrolledToTarget = false;
  double _swipeStartY = 0.0;
  double _swipeStartX = 0.0;
  bool _isSwipingDown = false;
  bool _textSettingsAppBarVisible = false;

  @override
  void initState() {
    super.initState();
    isMushafTextSettingsAppBarVisible().then((visible) {
      if (mounted) setState(() => _textSettingsAppBarVisible = visible);
    });
  }

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
      return _MushafPageSnapshot.glyph(content);
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
  void didUpdateWidget(MushafPage oldWidget) {
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
    final appLanguage = settings.appLanguage;
    ref.watch(settingsProvider.select((s) => s.showTajweed));
    final surahsAsync = ref.watch(surahNamesProvider);
    
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
          // Detect downward swipe (positive deltaY) and ensure vertical movement is greater than horizontal
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
          
          // Swipe down gesture detected - ensure vertical velocity is greater than horizontal
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
        appBar: AppBar(
          leading: readerAppBarBackButton(context),
          automaticallyImplyLeading: false,
          toolbarHeight: 54,
          centerTitle: false,
          titleSpacing: 0,
          title: FutureBuilder<List<int>>(
            future: MushafLayout.getSurahIdsForPage(widget.pageNo),
            builder: (context, surahIdsSnapshot) {
              final pageTitle = AppLocalizations.getMushafPageText(
                widget.pageNo,
                appLanguage,
              );
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

                  String formatSurahName(String name) {
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

                  final firstSurahName = formatSurahName(firstSurah.englishName);
                  final lastSurahName = formatSurahName(lastSurah.englishName);
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
          actions: [
            if (_textSettingsAppBarVisible)
              IconButton(
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
                  ).then((_) {
                    setState(() {
                      _refreshLines();
                    });
                  });
                },
              ),
          ],
          bottom: readerAppBarBottomDivider(colorScheme),
        ),
      body: FutureBuilder<_MushafPageSnapshot>(
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
          
          // Scroll to target ayah if needed
          if (widget.targetSurahId != null && widget.targetAyahNo != null && !_hasScrolledToTarget) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasScrolledToTarget) {
                _scrollToTargetAyah();
              }
            });
          }
          
          final audio = ref.watch(audioPlayerProvider);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                if (!audio.isActive) ...[
                  const MushafGestureHintBanner(),
                  MushafOfflineAudioBanner(pageNo: widget.pageNo),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        if (pageData.isGlyph)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return QpcV2MushafText(
                                content: pageData.glyphContent!,
                                contentWidth: constraints.maxWidth,
                                fontSize: fontSize,
                                colorScheme: colorScheme,
                                ayahKeys: _ayahKeys,
                                onAyahTap: widget.onAyahTap,
                                onAyahLongPress: widget.onAyahLongPress,
                                onBismillahTap: widget.onBismillahTap,
                                onBismillahLongPress:
                                    widget.onBismillahLongPress,
                                onAyahKeyCreated: () {
                                  if (widget.targetSurahId != null &&
                                      widget.targetAyahNo != null) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      _scrollToTargetAyah();
                                    });
                                  }
                                },
                              );
                            },
                          )
                        else
                          _FlowingMushafText(
                            blocks: pageData.legacyBlocks ?? [],
                            fontSize: fontSize,
                            colorScheme: colorScheme,
                            ayahKeys: _ayahKeys,
                            selectedSurahId: widget.selectedSurahId,
                            selectedAyahNo: widget.selectedAyahNo,
                            onAyahTap: widget.onAyahTap,
                            onAyahLongPress: widget.onAyahLongPress,
                            onBismillahTap: widget.onBismillahTap,
                            onBismillahLongPress: widget.onBismillahLongPress,
                            onAyahKeyCreated: () {
                              if (widget.targetSurahId != null &&
                                  widget.targetAyahNo != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _scrollToTargetAyah();
                                });
                              }
                            },
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: MushafPageNumberBadge(pageNo: widget.pageNo),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const GlobalRecitationBar(),
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
    final settings = ref.watch(settingsProvider);
    final showTajweed = settings.showTajweed;
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
      final defaultSpanStyle = TextStyle(
        fontFamily: 'UthmanicHafsV22',
        fontFamilyFallback: const ['UthmanicHafs'],
        fontSize: fontSize,
        color: colorScheme.onSurface,
      );
      if (showTajweed && block.tajweed != null && block.tajweed!.isNotEmpty) {
        var parsedSpans = TajweedParser.parseToSpans(
          context: context,
          tajweedHtml: block.tajweed!,
          baseStyle: defaultSpanStyle,
          defaultColor: colorScheme.onSurface,
          recognizer: recognizer,
          backgroundColor: recitationHighlight,
        );
        parsedSpans = TajweedText.coalesceSpansForArabicLayout(
          parsedSpans,
          defaultStyle: defaultSpanStyle,
        );
        ayahSpans.addAll(parsedSpans);
      } else {
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
      }

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
                                  notifier.stop();
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
                              isPlayingThis ? Icons.stop : Icons.play_arrow,
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

