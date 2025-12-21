import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';
import 'package:quran_offline/features/read/widgets/mushaf_text_settings_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    // For RTL swipe: page 1 = index 603 (last), page 604 = index 0 (first)
    // So initialPage 1 should be at index 603, initialPage 604 at index 0
    final initialIndex = 604 - widget.initialPage;
    _controller = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch settings to react to font size changes
    ref.watch(settingsProvider.select((s) => s.mushafFontSize));
    
    return PageView.builder(
      controller: _controller,
      reverse: true, // RTL swipe: swipe left = next page, swipe right = prev page
      itemCount: 604,
      itemBuilder: (context, index) {
        // Convert index to page number: index 0 = page 604, index 603 = page 1
        final pageNo = 604 - index;
        return MushafPage(
          pageNo: pageNo,
          targetSurahId: widget.targetSurahId,
          targetAyahNo: widget.targetAyahNo,
          onComputed: () {
            // Preload previous page in background (optional optimization)
            if (pageNo > 1) {
              MushafLayout.getPageBlocks(context, pageNo - 1);
            }
          },
        );
      },
    );
  }
}

class MushafPage extends ConsumerStatefulWidget {
  final int pageNo;
  final int? targetSurahId;
  final int? targetAyahNo;
  final VoidCallback? onComputed;

  const MushafPage({
    super.key,
    required this.pageNo,
    this.targetSurahId,
    this.targetAyahNo,
    this.onComputed,
  });

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late Future<List<MushafAyahBlock>> _blocksFuture;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  Timer? _debounceTimer;
  bool _hasScrolledToTarget = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshLines();
    _setupScrollListener();
  }

  void _refreshLines() {
    _blocksFuture = MushafLayout.getPageBlocks(context, widget.pageNo);
  }

  void _setupScrollListener() {
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
  }

  void _onItemPositionsChanged() {
    if (!mounted) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _updateLastRead();
    });
  }

  void _updateLastRead() {
    if (!mounted) return;
    
    // Get blocks to find visible ayah
    _blocksFuture.then((blocks) {
      if (!mounted || blocks.isEmpty) return;
      
      // Get current item positions
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;
      
      // Find the first visible item (top of viewport)
      final visiblePositions = positions.where((pos) => pos.itemTrailingEdge > 0 && pos.itemLeadingEdge < 1.0).toList();
      if (visiblePositions.isEmpty) return;
      
      // Sort by itemLeadingEdge to get the one closest to top
      visiblePositions.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
      final topVisible = visiblePositions.first;
      
      if (topVisible.index < 0 || topVisible.index >= blocks.length) return;
      
      final block = blocks[topVisible.index];
      if (block.surahId != null && block.ayahNo != null) {
        final source = PageSource(widget.pageNo);
        ref.read(lastReadProvider.notifier).saveLastRead(
          source,
          ayahNo: block.ayahNo,
          surahId: block.surahId,
        );
      }
    });
  }

  void _scrollToTargetAyah(List<MushafAyahBlock> blocks) {
    if (_hasScrolledToTarget) return;
    if (widget.targetSurahId == null || widget.targetAyahNo == null) return;
    
    // Find the index of the target ayah
    int? targetIndex;
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.surahId == widget.targetSurahId && block.ayahNo == widget.targetAyahNo) {
        targetIndex = i;
        break;
      }
    }
    
    if (targetIndex == null) return;
    
    // Wait for initial frame, then scroll to item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasScrolledToTarget) return;
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _hasScrolledToTarget) return;
        
        try {
          _itemScrollController.scrollTo(
            index: targetIndex!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.15, // Position 15% from top of viewport
          );
          
          // Mark as successful after scroll completes
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _hasScrolledToTarget = true;
            }
          });
        } catch (e) {
          // If scroll fails, mark as done to prevent infinite retries
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
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNo != widget.pageNo) {
      _refreshLines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final fontSize = settings.mushafFontSize;
    final appLanguage = settings.appLanguage;
    // Watch showTajweed to trigger rebuild when toggled
    ref.watch(settingsProvider.select((s) => s.showTajweed));
    final surahsAsync = ref.watch(surahNamesProvider);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
        title: FutureBuilder<List<int>>(
          future: MushafLayout.getSurahIdsForPage(widget.pageNo),
          builder: (context, surahIdsSnapshot) {
            return surahsAsync.when(
              data: (surahs) {
                final surahIds = surahIdsSnapshot.data ?? [];
                if (surahIds.isEmpty) {
                  return Text(
                    AppLocalizations.getMushafPageText(widget.pageNo, appLanguage),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                  );
                }

                // Get first and last surah names
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

                // Format surah names with proper diacritics for common surahs
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

                // Format subtitle: "Surah FirstName - Surah LastName" for multiple, "Surah Name" for single
                String subtitle;
                if (surahIds.length == 1) {
                  subtitle = 'Surah $firstSurahName';
                } else {
                  subtitle = 'Surah $firstSurahName - Surah $lastSurahName';
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Line 1: "Mushaf - Page 604" (titleLarge, bold)
                    Text(
                      AppLocalizations.getMushafPageText(widget.pageNo, appLanguage),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    // Line 2: "Surah Al-Ikhlas - Surah An Naas" (labelMedium/bodySmall, muted)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.2,
                          ) ??
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.2,
                              ),
                    ),
                  ],
                );
              },
              loading: () => Text(
                AppLocalizations.getMushafPageText(widget.pageNo, appLanguage),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
              ),
              error: (_, __) => Text(
                AppLocalizations.getMushafPageText(widget.pageNo, appLanguage),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Text settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const MushafTextSettingsDialog(),
              ).then((_) {
                // Refresh lines when dialog closes (font size may have changed)
                setState(() {
                  _refreshLines();
                });
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      body: FutureBuilder<List<MushafAyahBlock>>(
        future: _blocksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final blocks = snapshot.data ?? [];
          widget.onComputed?.call();
          
          // Scroll to target ayah if needed
          if (widget.targetSurahId != null && widget.targetAyahNo != null && !_hasScrolledToTarget) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasScrolledToTarget) {
                _scrollToTargetAyah(blocks);
              }
            });
          }
          
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                Expanded(
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    itemCount: blocks.length,
                    itemBuilder: (context, index) {
                      final block = blocks[index];
                        if (block.isSurahHeader) {
                          // Shadow yang adaptif ke theme dan nyaman untuk mata
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final shadowColor = isDark
                              ? colorScheme.primary.withOpacity(0.15)
                              : colorScheme.primary.withOpacity(0.12);
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                block.text,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontFamily: 'UthmanicHafsV22',
                                      fontFamilyFallback: const ['UthmanicHafs'],
                                      fontSize: fontSize + 4,
                                      fontWeight: FontWeight.w600,
                                      height: 1.7,
                                      color: colorScheme.onSurface,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: shadowColor,
                                          offset: const Offset(0, 1.5),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          );
                        }

                        if (block.isBismillah) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                block.text,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontFamily: 'UthmanicHafsV22',
                                      fontFamilyFallback: const ['UthmanicHafs'],
                                      fontSize: fontSize - 2,
                                      height: 1.7,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          );
                        }

                        // Default: ayah block with prefix badge
                        return _AyahRow(
                          block: block,
                          fontSize: fontSize,
                          colorScheme: colorScheme,
                          pageNo: widget.pageNo,
                        );
                    },
                    padding: const EdgeInsets.only(bottom: 32),
                  ),
                ),
                Text(
                  '${widget.pageNo}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AyahRow extends ConsumerStatefulWidget {
  final MushafAyahBlock block;
  final double fontSize;
  final ColorScheme colorScheme;
  final int pageNo;

  const _AyahRow({
    required this.block,
    required this.fontSize,
    required this.colorScheme,
    required this.pageNo,
  });

  @override
  ConsumerState<_AyahRow> createState() => _AyahRowState();
}

class _AyahRowState extends ConsumerState<_AyahRow> {
  bool _isBookmarked = false;
  bool _isCheckingBookmark = true;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    if (widget.block.surahId == null || widget.block.ayahNo == null) {
      setState(() {
        _isCheckingBookmark = false;
      });
      return;
    }

    final bookmarked = await isBookmarked(
      ref,
      widget.block.surahId!,
      widget.block.ayahNo!,
    );
    
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
        _isCheckingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.block.surahId == null || widget.block.ayahNo == null) return;
    
    await toggleBookmark(
      ref,
      widget.block.surahId!,
      widget.block.ayahNo!,
    );
    
    await _checkBookmark();
  }

  @override
  Widget build(BuildContext context) {
    final ayahNo = widget.block.ayahNo ?? 0;
    final badgeSize = 48.0;
    final settings = ref.watch(settingsProvider);
    final showTajweed = settings.showTajweed && widget.block.tajweed != null && widget.block.tajweed!.isNotEmpty;
    final canBookmark = widget.block.surahId != null && widget.block.ayahNo != null;
    
    // Listen to bookmark refresh to update when bookmarks change elsewhere
    ref.listen(bookmarkRefreshProvider, (previous, next) {
      if (previous != next && canBookmark) {
        _checkBookmark();
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AyahBadge(
                  ayahNo: ayahNo,
                  size: badgeSize,
                  colorScheme: widget.colorScheme,
                ),
                if (canBookmark) ...[
                  const SizedBox(height: 4),
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      size: 18,
                    ),
                    color: _isBookmarked 
                        ? widget.colorScheme.primary 
                        : widget.colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark',
                    onPressed: _isCheckingBookmark ? null : _toggleBookmark,
                  ),
                ],
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: showTajweed
                  ? TajweedText(
                      tajweedHtml: widget.block.tajweed!,
                      fontSize: widget.fontSize,
                      defaultColor: widget.colorScheme.onSurface,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      height: 1.8,
                    )
                  : Text(
                      widget.block.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'UthmanicHafsV22',
                        fontFamilyFallback: const ['UthmanicHafs'],
                        fontSize: widget.fontSize,
                        height: 1.8,
                        color: widget.colorScheme.onSurface,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahBadge extends StatelessWidget {
  final int ayahNo;
  final double size;
  final ColorScheme colorScheme;

  const _AyahBadge({
    required this.ayahNo,
    required this.size,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final displayNumber = MushafLayout.toArabicIndicDigits(ayahNo.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simple badge - hanya nomor, tanpa background circle
    return Text(
      displayNumber,
      style: TextStyle(
        fontSize: size * 0.7, // Font lebih besar
        height: 1.0,
        fontFamily: 'UthmanicHafsV22',
        fontFamilyFallback: const ['UthmanicHafs'],
        color: isDark
            ? Colors.white // Putih di dark mode untuk kontras
            : Colors.black87, // Hitam di light mode
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
      ),
    );
  }
}



