import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/utils/juz_info.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/features/reader/ayah_card.dart';
import 'package:quran_offline/features/reader/surah_header_card.dart';
import 'package:quran_offline/features/reader/text_settings_dialog.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _hasScrolledToTarget = false;
  double _swipeStartX = 0.0;
  double _swipeStartY = 0.0;
  bool _isSwiping = false;
  bool _scrollListenerSetup = false;
  
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scrollListenerSetup) {
      _setupScrollListener();
    }
  }
  
  void _setupScrollListener() {
    if (_scrollListenerSetup) return;
    _scrollListenerSetup = true;
    
    // Listen to item positions changes using ValueNotifier
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
  }
  
  Timer? _debounceTimer;
  
  void _onItemPositionsChanged() {
    if (!mounted) return;
    
    final source = ref.read(readerSourceProvider);
    if (source == null || (source is! SurahSource && source is! JuzSource)) return;
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Get current item positions
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    
    // Find the item that is currently at the top of the viewport
    // itemLeadingEdge: position of leading edge (0 = top of viewport, negative = above, >1 = below)
    // itemTrailingEdge: position of trailing edge
    // We want the item whose leading edge is closest to 0 (top of viewport) but still visible
    final visiblePositions = positions.where((pos) {
      // Item is visible if it has passed the top (trailingEdge > 0) and hasn't completely passed bottom (leadingEdge < 1)
      return pos.itemTrailingEdge > 0 && pos.itemLeadingEdge < 1.0 && pos.index >= 0;
    }).toList();
    
    int? targetIndex;
    if (visiblePositions.isNotEmpty) {
      // Sort by itemLeadingEdge ascending - the one with smallest leading edge is closest to top
      visiblePositions.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
      // Take the first one (closest to top, but make sure it's actually visible)
      final topItem = visiblePositions.first;
      // Use the item that is most visible at the top
      // If the top item's leading edge is very negative (way above viewport), use the next one
      // Otherwise, use the top item
      if (topItem.itemLeadingEdge < -0.3 && visiblePositions.length > 1) {
        // Top item is too far above, use the next visible item
        targetIndex = visiblePositions[1].index;
      } else {
        // Use the top item (closest to top of viewport)
        targetIndex = topItem.index;
      }
    }
    
    // Fallback: if no good match, use the first item that has passed top
    if (targetIndex == null) {
      final passedTop = positions.where((pos) => pos.itemTrailingEdge > 0 && pos.index >= 0).toList();
      if (passedTop.isNotEmpty) {
        passedTop.sort((a, b) => a.itemTrailingEdge.compareTo(b.itemTrailingEdge));
        targetIndex = passedTop.first.index;
      }
    }
    
    if (targetIndex == null || targetIndex < 0) return;
    
    // Debounce: wait 500ms after scroll stops before updating
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _updateLastRead(source, targetIndex!);
      }
    });
  }
  
  void _updateLastRead(ReaderSource source, int itemIndex) {
    // Get verses to find ayah number
    final versesAsync = ref.read(readerVersesProvider(source));
    versesAsync.whenData((verses) {
      if (!mounted || verses.isEmpty) return;
      
      // For SurahSource and SurahInJuzSource, check if we have a header (index 0)
      // For JuzSource, no header, so itemIndex directly maps to verseIndex
      final isSurahSource = source is SurahSource || source is SurahInJuzSource;
      final hasHeader = isSurahSource && itemIndex > 0;
      final verseIndex = hasHeader ? itemIndex - 1 : itemIndex;
      
      if (verseIndex >= 0 && verseIndex < verses.length) {
        final visibleAyah = verses[verseIndex].ayahNo;
        final currentSource = ref.read(readerSourceProvider);
        
        if (source is SurahSource && currentSource is SurahSource && currentSource.surahId == source.surahId) {
          ref.read(lastReadProvider.notifier).saveLastRead(currentSource, ayahNo: visibleAyah);
        } else if (source is JuzSource && currentSource is JuzSource && currentSource.juzNo == source.juzNo) {
          ref.read(lastReadProvider.notifier).saveLastRead(currentSource, ayahNo: visibleAyah);
        } else if (source is SurahInJuzSource && currentSource is SurahInJuzSource && 
                   currentSource.juzNo == source.juzNo && currentSource.surahId == source.surahId) {
          ref.read(lastReadProvider.notifier).saveLastRead(currentSource, ayahNo: visibleAyah);
        }
      }
    });
  }
  
  @override
  void dispose() {
    // Cancel debounce timer
    _debounceTimer?.cancel();
    // Remove listener
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    super.dispose();
  }
  
  /// Navigate to next/previous surah, juz, or page based on swipe direction
  void _handleSwipeNavigation(ReaderSource currentSource, bool isNext) {
    if (currentSource is SurahInJuzSource) {
      _handleSurahInJuzNavigation(currentSource, isNext);
      return;
    }
    
    final newSource = switch (currentSource) {
      SurahSource(:final surahId) => () {
        final nextSurahId = isNext ? surahId + 1 : surahId - 1;
        if (nextSurahId >= 1 && nextSurahId <= 114) {
          return SurahSource(nextSurahId);
        }
        return null;
      }(),
      JuzSource(:final juzNo) => () {
        final nextJuzNo = isNext ? juzNo + 1 : juzNo - 1;
        if (nextJuzNo >= 1 && nextJuzNo <= 30) {
          return JuzSource(nextJuzNo);
        }
        return null;
      }(),
      PageSource(:final pageNo) => () {
        final nextPageNo = isNext ? pageNo + 1 : pageNo - 1;
        if (nextPageNo >= 1 && nextPageNo <= 604) {
          return PageSource(nextPageNo);
        }
        return null;
      }(),
      _ => null,
    };
    
    if (newSource != null) {
      ref.read(readerSourceProvider.notifier).state = newSource;
      ref.read(targetAyahProvider.notifier).state = null;
    }
  }
  
  /// Handle navigation for SurahInJuzSource (async operation)
  void _handleSurahInJuzNavigation(SurahInJuzSource source, bool isNext) async {
    final db = ref.read(databaseProvider);
    final juzSurahs = await db.getSurahIdsInJuz(source.juzNo);
    
    if (juzSurahs.isEmpty) return;
    
    final currentIndex = juzSurahs.indexOf(source.surahId);
    if (currentIndex == -1) return;
    
    ReaderSource? newSource;
    
    if (isNext) {
      // Next Surah in same Juz
      if (currentIndex < juzSurahs.length - 1) {
        newSource = SurahInJuzSource(source.juzNo, juzSurahs[currentIndex + 1]);
      } else if (source.juzNo < 30) {
        // Last Surah in Juz, go to next Juz
        final nextJuzSurahs = await db.getSurahIdsInJuz(source.juzNo + 1);
        if (nextJuzSurahs.isNotEmpty) {
          newSource = SurahInJuzSource(source.juzNo + 1, nextJuzSurahs.first);
        }
      }
    } else {
      // Previous Surah in same Juz
      if (currentIndex > 0) {
        newSource = SurahInJuzSource(source.juzNo, juzSurahs[currentIndex - 1]);
      } else if (source.juzNo > 1) {
        // First Surah in Juz, go to previous Juz
        final prevJuzSurahs = await db.getSurahIdsInJuz(source.juzNo - 1);
        if (prevJuzSurahs.isNotEmpty) {
          newSource = SurahInJuzSource(source.juzNo - 1, prevJuzSurahs.last);
        }
      }
    }
    
    if (newSource != null && mounted) {
      ref.read(readerSourceProvider.notifier).state = newSource;
      ref.read(targetAyahProvider.notifier).state = null;
    }
  }
  
  void _scrollToAyah(List<Verse> verses, int targetAyahNo, bool isSurahSource, bool hasHeader) {
    if (_hasScrolledToTarget) return;
    
    // Find the index of the target ayah in the verses list
    int? targetIndex;
    for (int i = 0; i < verses.length; i++) {
      if (verses[i].ayahNo == targetAyahNo) {
        targetIndex = i;
        break;
      }
    }
    
    if (targetIndex == null) return;
    
    // Adjust index if header is present (header is at index 0)
    final itemIndex = isSurahSource && hasHeader ? targetIndex + 1 : targetIndex;
    
    // Wait for initial frame, then scroll to item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasScrolledToTarget) return;
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _hasScrolledToTarget) return;
        
        try {
          _itemScrollController.scrollTo(
            index: itemIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.15, // Position 15% from top of viewport
          );
          
          // Mark as successful after scroll completes
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _hasScrolledToTarget = true;
              ref.read(targetAyahProvider.notifier).state = null;
            }
          });
        } catch (e) {
          // If scroll fails, mark as done to prevent infinite retries
          if (mounted) {
            _hasScrolledToTarget = true;
            ref.read(targetAyahProvider.notifier).state = null;
          }
        }
      });
    });
  }

  /// Build premium 2-line editorial AppBar for Juz reading
  PreferredSizeWidget _buildJuzAppBar(
    BuildContext context,
    WidgetRef ref,
    int juzNo,
  ) {
    final juzSurahsAsync = ref.watch(juzSurahsProvider(juzNo));
    final surahsAsync = ref.watch(surahNamesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final totalAyah = JuzInfo.getTotalAyah(juzNo) ?? 0;

    return AppBar(
      leading: Navigator.canPop(context) ? const BackButton() : null,
      automaticallyImplyLeading: false,
      toolbarHeight: 54,
      centerTitle: false,
      titleSpacing: 16,
      title: juzSurahsAsync.when(
        data: (juzSurahs) {
          return surahsAsync.when(
            data: (surahs) {
              if (juzSurahs.surahIds.isEmpty) {
                return Text(
                  'Juz $juzNo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                );
              }

              // Get first and last surah names
              final firstSurahId = juzSurahs.surahIds.first;
              final lastSurahId = juzSurahs.surahIds.last;
              
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
              
              // Build subtitle: "148 ayah • Al-Fātiḥah → Al-Baqarah"
              final subtitle = totalAyah > 0
                  ? '$totalAyah ayah • $firstSurahName → $lastSurahName'
                  : '$firstSurahName → $lastSurahName';

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Line 1: "Juz 1" (titleLarge, bold)
                  Text(
                    'Juz $juzNo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  // Line 2: "148 ayah • Al-Fātiḥah → Al-Baqarah" (labelMedium/bodySmall, muted)
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
            loading: () => Text(
              'Juz $juzNo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            error: (_, __) => Text(
              'Juz $juzNo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          );
        },
        loading: () => Text(
          'Juz $juzNo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        error: (_, __) => Text(
          'Juz $juzNo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
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
              builder: (context) => const TextSettingsDialog(),
            );
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
    );
  }

  /// Build AppBar for SurahInJuzSource showing Surah name and Juz number
  PreferredSizeWidget _buildSurahInJuzAppBar(
    BuildContext context,
    WidgetRef ref,
    int juzNo,
    int surahId,
  ) {
    final surahsAsync = ref.watch(surahNamesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: Navigator.canPop(context) ? const BackButton() : null,
      automaticallyImplyLeading: false,
      toolbarHeight: 54,
      centerTitle: false,
      titleSpacing: 16,
      title: surahsAsync.when(
        data: (surahs) {
          final surah = surahs.firstWhere(
            (s) => s.id == surahId,
            orElse: () => SurahInfo(
              id: surahId,
              arabicName: '',
              englishName: 'Surah $surahId',
              englishMeaning: '',
            ),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Line 1: Surah name (titleLarge, bold)
              Text(
                surah.englishName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 2),
              // Line 2: "Juz X" (labelMedium/bodySmall, muted)
              Text(
                'Juz $juzNo',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ) ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
        loading: () => Text(
          'Surah $surahId',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        error: (_, __) => Text(
          'Surah $surahId',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
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
              builder: (context) => const TextSettingsDialog(),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(readerSourceProvider);
    final isLargeScreen = Responsive.isLargeScreen(context);
    final surahsAsync = ref.watch(surahNamesProvider);
    
    // Listen to source changes reactively (ref.listen automatically handles lifecycle)
    ref.listen<ReaderSource?>(readerSourceProvider, (previous, next) {
      if (previous != next && next != null) {
        // Save last read (without ayahNo, will be updated when user scrolls)
        ref.read(lastReadProvider.notifier).saveLastRead(next);
        setState(() {
          _hasScrolledToTarget = false;
        });
        // Optionally reset scroll position
        try {
          _itemScrollController.jumpTo(index: 0);
        } catch (e) {
          // Ignore if scroll controller not ready
        }
      }
    });
    
    // Listen to target ayah changes
    ref.listen<int?>(targetAyahProvider, (previous, next) {
      if (next != null && next != previous) {
        setState(() {
          _hasScrolledToTarget = false;
        });
      }
    });
    
    if (source == null && !isLargeScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reader'),
        ),
        body: const Center(
          child: Text('Select a surah, juz, or page to read'),
        ),
      );
    }

    if (source == null) {
      return const Center(
        child: Text('Select a surah, juz, or page to read'),
      );
    }

    final versesAsync = ref.watch(readerVersesProvider(source));

    // AppBar with 2-line editorial title for Juz, minimal for Page/Surah
    final appBar = isLargeScreen
        ? null
        : switch (source) {
            JuzSource(:final juzNo) => _buildJuzAppBar(context, ref, juzNo),
            SurahInJuzSource(:final juzNo, :final surahId) => _buildSurahInJuzAppBar(context, ref, juzNo, surahId),
            PageSource(:final pageNo) => AppBar(
                leading: Navigator.canPop(context) ? const BackButton() : null,
                automaticallyImplyLeading: false,
                toolbarHeight: 54,
                centerTitle: false,
                titleSpacing: 16,
                title: Text('Page $pageNo'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    tooltip: 'Text settings',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const TextSettingsDialog(),
                      );
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.3),
                  ),
                ),
              ),
            _ => AppBar(
                leading: Navigator.canPop(context) ? const BackButton() : null,
                automaticallyImplyLeading: false,
                toolbarHeight: 54,
                centerTitle: false,
                titleSpacing: 16,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    tooltip: 'Text settings',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const TextSettingsDialog(),
                      );
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.3),
                  ),
                ),
              ), // No title for Surah (header card shows surah name)
          };

    return Scaffold(
      appBar: appBar,
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
          
          if (deltaX.abs() > swipeThreshold && deltaX.abs() > deltaY.abs() && source != null) {
            // Swipe left (negative deltaX) = next
            // Swipe right (positive deltaX) = previous
            final isNext = deltaX < 0;
            _handleSwipeNavigation(source, isNext);
          }
          
          _isSwiping = false;
        },
        child: versesAsync.when(
          data: (verses) {
            if (verses.isEmpty) {
              return const Center(child: Text('No verses found'));
            }

            final contentWidth = Responsive.getContentWidth(context);
            final isLargeScreen = Responsive.isLargeScreen(context);

            return Center(
              child: SizedBox(
                width: isLargeScreen ? contentWidth : double.infinity,
                child: surahsAsync.when(
                data: (surahs) {
                  final settings = ref.watch(settingsProvider);
                  final isSurahSource = source is SurahSource || source is SurahInJuzSource;
                  
                  // Calculate verse count for current surah (when reading by surah)
                  final currentSurahId = isSurahSource && verses.isNotEmpty ? verses[0].surahId : null;
                  final verseCount = currentSurahId != null ? verses.length : 0;
                  final currentSurahInfo = currentSurahId != null
                      ? surahs.firstWhere(
                          (s) => s.id == currentSurahId,
                          orElse: () => SurahInfo(
                            id: currentSurahId,
                            arabicName: '',
                            englishName: 'Surah $currentSurahId',
                            englishMeaning: '',
                          ),
                        )
                      : null;

                  // Scroll to target ayah if needed - trigger as soon as verses are loaded
                  final targetAyah = ref.watch(targetAyahProvider);
                  final isJuzSource = source is JuzSource;
                  
                  // Trigger scroll immediately when conditions are met (for both Surah and Juz)
                  if (targetAyah != null && (isSurahSource || isJuzSource) && !_hasScrolledToTarget) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_hasScrolledToTarget) {
                        _scrollToAyah(verses, targetAyah, isSurahSource, currentSurahInfo != null);
                      }
                    });
                  }
                  
                  return ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: verses.length + (isSurahSource && currentSurahInfo != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show header card at the top for surah reading
                      if (isSurahSource && currentSurahInfo != null && index == 0) {
                        return SurahHeaderCard(
                          surahInfo: currentSurahInfo,
                          verseCount: verseCount,
                        );
                      }

                      // Adjust index for verses (subtract 1 if header was shown)
                      final verseIndex = isSurahSource && currentSurahInfo != null ? index - 1 : index;
                      final verse = verses[verseIndex];
                      final prevSurah = verseIndex > 0 ? verses[verseIndex - 1].surahId : null;
                      final showSurahDivider = prevSurah != null && prevSurah != verse.surahId;
                      final isFirstAyah = verse.ayahNo == 1;
                      // For Surah mode and SurahInJuz mode we already inject a header at index 0; avoid double header.
                      final showSurahHeader = !isSurahSource && (verseIndex == 0 || showSurahDivider);

                      final surahInfo = surahs.firstWhere(
                        (s) => s.id == verse.surahId,
                        orElse: () => SurahInfo(
                              id: verse.surahId,
                              arabicName: '',
                              englishName: 'Surah ${verse.surahId}',
                              englishMeaning: '',
                            ),
                      );

                      return Column(
                        children: [
                          // Surah header for first surah in Juz/Page and on surah transitions
                          if (showSurahHeader) ...[
                            SurahHeaderCard(
                              surahInfo: surahInfo,
                              verseCount: verses.where((v) => v.surahId == verse.surahId).length,
                            ),
                          ],
                          // Show Bismillah before first ayah of each surah (except Surah 1 and Surah 9)
                          // Note: Surah 1's first ayah IS the Bismillah, so we don't show it separately
                          if (isFirstAyah && Bismillah.shouldShowBismillah(verse.surahId)) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Opacity(
                                          opacity: 0,
                                          child: Text(
                                            '${verse.surahId}:${verse.ayahNo}',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Opacity(
                                          opacity: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.bookmark_outline, size: 20),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {},
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SelectableText(
                                          Bismillah.arabic,
                                          style: TextStyle(
                                            fontSize: settings.arabicFontSize * 1.1,
                                            fontFamily: 'UthmanicHafsV22',
                                            fontFamilyFallback: const ['UthmanicHafs'],
                                            height: 1.7,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                    if (settings.showTransliteration) ...[
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        Bismillah.transliteration,
                                        style: TextStyle(
                                          fontSize: settings.translationFontSize * 0.85,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      Bismillah.getTranslation(settings.language),
                                      style: TextStyle(
                                        fontSize: settings.translationFontSize,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                AyahCard(verse: verse),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () {
                  final settings = ref.watch(settingsProvider);
                  final isSurahSource = source is SurahSource || source is SurahInJuzSource;
                  
                  return ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final verse = verses[index];
                      final prevSurah = index > 0 ? verses[index - 1].surahId : null;
                      final showSurahDivider = prevSurah != null && prevSurah != verse.surahId;
                      final isFirstAyah = verse.ayahNo == 1;
                      final isFirstVerse = index == 0;

                      return Column(
                        children: [
                          if (isSurahSource && isFirstVerse) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                            ),
                          ],
                          if (showSurahDivider) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                            ),
                          ],
                          if (isFirstAyah && Bismillah.shouldShowBismillah(verse.surahId)) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Opacity(
                                          opacity: 0,
                                          child: Text(
                                            '${verse.surahId}:${verse.ayahNo}',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Opacity(
                                          opacity: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.bookmark_outline, size: 20),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {},
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SelectableText(
                                          Bismillah.arabic,
                                          style: TextStyle(
                                            fontSize: settings.arabicFontSize * 1.1,
                                            fontFamily: 'UthmanicHafsV22',
                                            fontFamilyFallback: const ['UthmanicHafs'],
                                            height: 1.7,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                    if (settings.showTransliteration) ...[
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        Bismillah.transliteration,
                                        style: TextStyle(
                                          fontSize: settings.translationFontSize * 0.85,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      Bismillah.getTranslation(settings.language),
                                      style: TextStyle(
                                        fontSize: settings.translationFontSize,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                AyahCard(verse: verse),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                error: (_, __) {
                  final settings = ref.watch(settingsProvider);
                  final isSurahSource = source is SurahSource || source is SurahInJuzSource;
                  
                  return ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final verse = verses[index];
                      final prevSurah = index > 0 ? verses[index - 1].surahId : null;
                      final showSurahDivider = prevSurah != null && prevSurah != verse.surahId;
                      final isFirstAyah = verse.ayahNo == 1;
                      final isFirstVerse = index == 0;

                      return Column(
                        children: [
                          if (isSurahSource && isFirstVerse) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                            ),
                          ],
                          if (showSurahDivider) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                            ),
                          ],
                          if (isFirstAyah && Bismillah.shouldShowBismillah(verse.surahId)) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Opacity(
                                          opacity: 0,
                                          child: Text(
                                            '${verse.surahId}:${verse.ayahNo}',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Opacity(
                                          opacity: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.bookmark_outline, size: 20),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {},
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SelectableText(
                                          Bismillah.arabic,
                                          style: TextStyle(
                                            fontSize: settings.arabicFontSize * 1.1,
                                            fontFamily: 'UthmanicHafsV22',
                                            fontFamilyFallback: const ['UthmanicHafs'],
                                            height: 1.7,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                    if (settings.showTransliteration) ...[
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        Bismillah.transliteration,
                                        style: TextStyle(
                                          fontSize: settings.translationFontSize * 0.85,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      Bismillah.getTranslation(settings.language),
                                      style: TextStyle(
                                        fontSize: settings.translationFontSize,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                AyahCard(verse: verse),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      ),
    );
  }


}



