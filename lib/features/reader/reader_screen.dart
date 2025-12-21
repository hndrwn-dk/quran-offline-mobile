import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
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
  ReaderSource? _lastSource = null;
  double _swipeStartX = 0.0;
  double _swipeStartY = 0.0;
  bool _isSwiping = false;
  
  @override
  void dispose() {
    // ItemScrollController and ItemPositionsListener don't need explicit disposal
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _lastSource = ref.read(readerSourceProvider);
  }
  
  /// Navigate to next/previous surah, juz, or page based on swipe direction
  void _handleSwipeNavigation(ReaderSource currentSource, bool isNext) {
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
    };
    
    if (newSource != null) {
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

  String _getTitle(ReaderSource? source, List<SurahInfo>? surahs) {
    if (source == null) return 'Reader';
    return switch (source) {
      SurahSource(:final surahId) => surahs
              ?.firstWhere((s) => s.id == surahId, orElse: () => SurahInfo(id: surahId, arabicName: '', englishName: 'Surah $surahId', englishMeaning: ''))
              .englishName ??
          'Surah $surahId',
      JuzSource(:final juzNo) => 'Juz $juzNo',
      PageSource(:final pageNo) => 'Page $pageNo',
    };
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

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(readerSourceProvider);
    final isLargeScreen = Responsive.isLargeScreen(context);
    final surahsAsync = ref.watch(surahNamesProvider);
    
    // Listen to source changes reactively (ref.listen automatically handles lifecycle)
    ref.listen<ReaderSource?>(readerSourceProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          _hasScrolledToTarget = false;
          _lastSource = next;
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
                  final isSurahSource = source is SurahSource;
                  
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
                  
                  // Trigger scroll immediately when conditions are met
                  if (targetAyah != null && isSurahSource && !_hasScrolledToTarget) {
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
                      // For Surah mode we already inject a header at index 0; avoid double header.
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
                  final isSurahSource = source is SurahSource;
                  
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
                  final isSurahSource = source is SurahSource;
                  
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



