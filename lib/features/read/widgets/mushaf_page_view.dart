import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
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
    // Normal mapping: index 0 = page 1, index 603 = page 604
    // This allows swipe right-to-left (kanan ke kiri) = next page (like physical mushaf)
    final initialIndex = widget.initialPage - 1;
    _controller = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((s) => s.mushafFontSize));
    
    return PageView.builder(
      controller: _controller,
      reverse: false, // Normal direction: swipe right-to-left = next page (like physical mushaf)
      itemCount: 604,
      itemBuilder: (context, index) {
        // Normal mapping: index 0 = page 1, index 603 = page 604
        final pageNo = index + 1;
        return MushafPage(
          pageNo: pageNo,
          targetSurahId: widget.targetSurahId,
          targetAyahNo: widget.targetAyahNo,
          onComputed: () {
            if (pageNo < 604) {
              MushafLayout.getPageBlocks(context, pageNo + 1);
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
    _blocksFuture = MushafLayout.getPageBlocks(context, widget.pageNo);
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
    
    _blocksFuture.then((blocks) {
      if (!mounted || blocks.isEmpty) return;
      
      // Find the first visible ayah by checking scroll position
      // This is approximate - for exact tracking, we'd need to measure widget positions
      final scrollOffset = _scrollController.offset;
      
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

                // Format surah names with proper diacritics
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
                    Text(
                      AppLocalizations.getMushafPageText(widget.pageNo, appLanguage),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                _scrollToTargetAyah();
              }
            });
          }
          
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        _FlowingMushafText(
                          blocks: blocks,
                          fontSize: fontSize,
                          colorScheme: colorScheme,
                          ayahKeys: _ayahKeys,
                          onAyahKeyCreated: () {
                            // Trigger scroll after keys are created
                            if (widget.targetSurahId != null && widget.targetAyahNo != null) {
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

/// Widget untuk menampilkan teks mushaf yang mengalir
class _FlowingMushafText extends ConsumerWidget {
  final List<MushafAyahBlock> blocks;
  final double fontSize;
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;
  final VoidCallback? onAyahKeyCreated;

  const _FlowingMushafText({
    required this.blocks,
    required this.fontSize,
    required this.colorScheme,
    required this.ayahKeys,
    this.onAyahKeyCreated,
  });

  /// Handle long press on ayah text for bookmarking
  static Future<void> handleAyahLongPress(BuildContext context, WidgetRef ref, int surahId, int ayahNo) async {
    await toggleBookmark(ref, surahId, ayahNo);
    
    if (context.mounted) {
      final bookmarked = await isBookmarked(ref, surahId, ayahNo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookmarked 
              ? 'Ayat $ayahNo di-bookmark'
              : 'Bookmark ayat $ayahNo dihapus',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final showTajweed = settings.showTajweed;
    
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
                height: 2.0, // Line height lebih lega (dari 1.6)
                color: colorScheme.onSurface,
                letterSpacing: 0.3, // Letter spacing (dari 0.0)
                wordSpacing: 2.0, // Word spacing untuk breathing room
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
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final shadowColor = isDark
            ? colorScheme.primary.withOpacity(0.15)
            : colorScheme.primary.withOpacity(0.12);
        
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                block.text,
                textAlign: TextAlign.center,
                style: TextStyle(
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
          ),
        );
        continue;
      }

      if (block.isBismillah) {
        // Bismillah untuk surah selain 1 harus terpisah (centered), bukan mengalir
        // Karena Bismillah bukan bagian dari ayat surah tersebut
        // Hanya Surah 1 (Al-Fatihah) yang Bismillah-nya adalah ayat pertama
        flushCurrentSpans();
        
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                block.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'UthmanicHafsV22',
                  fontFamilyFallback: const ['UthmanicHafs'],
                  fontSize: fontSize - 2,
                  height: 1.7,
                  color: colorScheme.onSurface,
                ),
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

      // Add ayah text with tajweed support if enabled
      // Add long press recognizer for bookmark
      LongPressGestureRecognizer? recognizer;
      if (block.surahId != null && block.ayahNo != null) {
        recognizer = LongPressGestureRecognizer();
        recognizers.add(recognizer); // Track for disposal
        recognizer.onLongPress = () {
          HapticFeedback.mediumImpact();
          handleAyahLongPress(context, ref, block.surahId!, block.ayahNo!);
        };
      }
      
      if (showTajweed && block.tajweed != null && block.tajweed!.isNotEmpty) {
        // Parse tajweed HTML and add colored spans with recognizer
        final tajweedSpans = _parseTajweedHtml(
          context, 
          block.tajweed!, 
          fontSize, 
          colorScheme,
          recognizer: recognizer,
        );
        currentSpans.addAll(tajweedSpans);
      } else {
        // Plain text without tajweed with recognizer
        currentSpans.add(
          TextSpan(
            text: block.text,
            style: TextStyle(
              fontFamily: 'UthmanicHafsV22',
              fontFamilyFallback: const ['UthmanicHafs'],
              fontSize: fontSize,
              color: colorScheme.onSurface,
            ),
            recognizer: recognizer,
          ),
        );
      }

      // Add inline ayah number
      if (block.ayahNo != null) {
        currentSpans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
              child: KeyedSubtree(
              key: ayahKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6), // Naik dari 2 ke 6
                child: _InlineAyahNumber(
                  ayahNo: block.ayahNo!,
                  fontSize: fontSize,
                  colorScheme: colorScheme,
                  surahId: block.surahId,
                ),
              ),
            ),
          ),
        );
      }

      // Add space between ayahs - double space untuk breathing room
      currentSpans.add(
        TextSpan(
          text: '  ', // Double space untuk breathing room
          style: TextStyle(fontSize: fontSize * 0.5),
        ),
      );
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

  /// Parse tajweed HTML and return List<TextSpan> with colors
  List<TextSpan> _parseTajweedHtml(
    BuildContext context,
    String tajweedHtml,
    double fontSize,
    ColorScheme colorScheme, {
    GestureRecognizer? recognizer,
  }) {
    final spans = <TextSpan>[];
    String text = tajweedHtml;
    
    // Get tajweed color helper
    Color getTajweedColor(String tajweedClass) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return switch (tajweedClass) {
        'ikhfa' => isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00897B),
        'idgham' => isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
        'iqlab' => isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2),
        'ghunnah' => isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
        'qalqalah' => isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
        'ham_wasl' => colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        'laam_shamsiyah' => isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17),
        'madda_normal' => isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        'madda_permissible' => isDark ? const Color(0xFFA5D6A7) : const Color(0xFF388E3C),
        'madda_necessary' => isDark ? const Color(0xFF66BB6A) : const Color(0xFF1B5E20),
        'madda_obligatory' => isDark ? const Color(0xFF4CAF50) : const Color(0xFF0D47A1),
        'silent' => colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        _ => colorScheme.onSurface,
      };
    }
    
    // Pattern to match tajweed tags
    final tajweedPattern1 = RegExp(
      r'<tajweed\s+class="([^"]+)"\s*>(.*?)</tajweed>',
      dotAll: true,
      caseSensitive: false,
    );
    final tajweedPattern2 = RegExp(
      r"<tajweed\s+class='([^']+)'\s*>(.*?)</tajweed>",
      dotAll: true,
      caseSensitive: false,
    );
    final tajweedPattern3 = RegExp(
      r'<tajweed\s+class=([^>\s]+)\s*>(.*?)</tajweed>',
      dotAll: true,
      caseSensitive: false,
    );
    final tajweedPattern4 = RegExp(
      r'<tajweed\s*>(.*?)</tajweed>',
      dotAll: true,
      caseSensitive: false,
    );
    
    // Pattern for class tags: <class=value>content</class>
    final classPattern1 = RegExp(
      r'<class="([^"]+)"\s*>(.*?)</class>',
      dotAll: true,
      caseSensitive: false,
    );
    final classPattern2 = RegExp(
      r"<class='([^']+)'\s*>(.*?)</class>",
      dotAll: true,
      caseSensitive: false,
    );
    final classPattern3 = RegExp(
      r'<class=([^>\s]+)\s*>(.*?)</class>',
      dotAll: true,
      caseSensitive: false,
    );
    
    // Pattern for span tags: <span class=end>ayah_number</span>
    final spanPattern1 = RegExp(
      r'<span\s+class="([^"]+)"\s*>(.*?)</span>',
      dotAll: true,
      caseSensitive: false,
    );
    final spanPattern2 = RegExp(
      r"<span\s+class='([^']+)'\s*>(.*?)</span>",
      dotAll: true,
      caseSensitive: false,
    );
    final spanPattern3 = RegExp(
      r'<span\s+class=([^>\s]+)\s*>(.*?)</span>',
      dotAll: true,
      caseSensitive: false,
    );
    
    final htmlTagPattern = RegExp(r'<[^>]+>');
    final allMatches = <_TajweedMatch>[];
    
    bool isAlreadyMatched(int start, int end) {
      return allMatches.any((m) => m.start == start && m.end == end);
    }
    
    // Find all tajweed matches
    for (final match in tajweedPattern1.allMatches(text)) {
      allMatches.add(_TajweedMatch(
        start: match.start,
        end: match.end,
        classAttr: match.group(1) ?? '',
        content: match.group(2) ?? '',
        isSpan: false,
      ));
    }
    for (final match in tajweedPattern2.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: false,
        ));
      }
    }
    for (final match in tajweedPattern3.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: false,
        ));
      }
    }
    for (final match in tajweedPattern4.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: '',
          content: match.group(1) ?? '',
          isSpan: false,
        ));
      }
    }
    
    // Find class tags
    for (final match in classPattern1.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: false,
        ));
      }
    }
    for (final match in classPattern2.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: false,
        ));
      }
    }
    for (final match in classPattern3.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: false,
        ));
      }
    }
    
    // Find span tags (to skip class=end)
    for (final match in spanPattern1.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: true,
        ));
      }
    }
    for (final match in spanPattern2.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: true,
        ));
      }
    }
    for (final match in spanPattern3.allMatches(text)) {
      if (!isAlreadyMatched(match.start, match.end)) {
        allMatches.add(_TajweedMatch(
          start: match.start,
          end: match.end,
          classAttr: match.group(1) ?? '',
          content: match.group(2) ?? '',
          isSpan: true,
        ));
      }
    }
    
    // Sort matches by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    // Build text spans
    int lastIndex = 0;
    for (final match in allMatches) {
      // Add text before match
      if (match.start > lastIndex) {
        var beforeText = text.substring(lastIndex, match.start);
        beforeText = beforeText.replaceAll(htmlTagPattern, '');
        beforeText = beforeText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
        if (beforeText.isNotEmpty) {
          spans.add(TextSpan(
            text: beforeText,
            style: TextStyle(
              fontFamily: 'UthmanicHafsV22',
              fontFamilyFallback: const ['UthmanicHafs'],
              fontSize: fontSize,
              color: colorScheme.onSurface,
            ),
            recognizer: recognizer != null ? recognizer : null,
          ));
        }
      }
      
      // Handle span tags - skip class=end (ayah number marker)
      if (match.isSpan) {
        final classAttr = match.classAttr.trim();
        // Skip ayah number marker - we already display it as inline badge
        if (classAttr == 'end' || classAttr == '"end"' || classAttr == "'end'") {
          // Do nothing, just skip this match
          lastIndex = match.end;
          continue;
        } else {
          // Regular span (not end marker) - render it as plain text
          var content = match.content;
          content = content.replaceAll(htmlTagPattern, '');
          content = content.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
          if (content.isNotEmpty) {
            spans.add(TextSpan(
              text: content,
              style: TextStyle(
                fontFamily: 'UthmanicHafsV22',
                fontFamilyFallback: const ['UthmanicHafs'],
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
              recognizer: recognizer != null ? recognizer : null,
            ));
          }
          lastIndex = match.end;
          continue;
        }
      }
      
      // Add styled text for tajweed match
      final tajweedClass = match.classAttr.trim();
      var content = match.content;
      content = content.replaceAll(htmlTagPattern, '');
      content = content.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      
      if (content.isNotEmpty) {
        final color = getTajweedColor(tajweedClass);
        spans.add(TextSpan(
          text: content,
          style: TextStyle(
            fontFamily: 'UthmanicHafsV22',
            fontFamilyFallback: const ['UthmanicHafs'],
            fontSize: fontSize,
            color: color,
          ),
          recognizer: recognizer != null ? recognizer : null,
        ));
      }
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      var remainingText = text.substring(lastIndex);
      remainingText = remainingText.replaceAll(htmlTagPattern, '');
      remainingText = remainingText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: TextStyle(
            fontFamily: 'UthmanicHafsV22',
            fontFamilyFallback: const ['UthmanicHafs'],
            fontSize: fontSize,
            color: colorScheme.onSurface,
          ),
          recognizer: recognizer != null ? recognizer : null,
        ));
      }
    }
    
    // If no matches found, return plain text
    if (spans.isEmpty) {
      var cleanedText = text.replaceAll(htmlTagPattern, '');
      cleanedText = cleanedText.replaceAll(RegExp(r'<[^>]*$', caseSensitive: false), '');
      return [
        TextSpan(
          text: cleanedText,
          style: TextStyle(
            fontFamily: 'UthmanicHafsV22',
            fontFamilyFallback: const ['UthmanicHafs'],
            fontSize: fontSize,
            color: colorScheme.onSurface,
          ),
          recognizer: recognizer != null ? recognizer : null,
        )
      ];
    }
    
    return spans;
  }
}

class _TajweedMatch {
  final int start;
  final int end;
  final String classAttr;
  final String content;
  final bool isSpan;

  _TajweedMatch({
    required this.start,
    required this.end,
    required this.classAttr,
    required this.content,
    this.isSpan = false,
  });
}

/// Widget untuk nomor ayat inline dengan bookmark support
class _InlineAyahNumber extends ConsumerStatefulWidget {
  final int ayahNo;
  final double fontSize;
  final ColorScheme colorScheme;
  final int? surahId;

  const _InlineAyahNumber({
    required this.ayahNo,
    required this.fontSize,
    required this.colorScheme,
    this.surahId,
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
    
    return GestureDetector(
      onTap: widget.surahId != null && !_isCheckingBookmark ? _toggleBookmark : null,
      child: Container(
        padding: EdgeInsets.all(widget.fontSize * 0.15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isBookmarked
                ? widget.colorScheme.primary
                : widget.colorScheme.outline.withOpacity(0.3),
            width: _isBookmarked ? 2.0 : 1.5,
          ),
          color: _isBookmarked
              ? widget.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Text(
          displayNumber,
          style: TextStyle(
            fontSize: widget.fontSize * 0.6,
            fontFamily: 'UthmanicHafsV22',
            fontFamilyFallback: const ['UthmanicHafs'],
            color: _isBookmarked
                ? widget.colorScheme.primary
                : widget.colorScheme.onSurface,
            height: 1.0,
            fontWeight: _isBookmarked ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

