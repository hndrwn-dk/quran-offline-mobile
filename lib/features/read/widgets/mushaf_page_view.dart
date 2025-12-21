import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';
import 'package:quran_offline/features/read/widgets/mushaf_text_settings_dialog.dart';

class MushafPageView extends ConsumerStatefulWidget {
  final int initialPage;

  const MushafPageView({super.key, required this.initialPage});

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
  final VoidCallback? onComputed;

  const MushafPage({super.key, required this.pageNo, this.onComputed});

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late Future<List<MushafAyahBlock>> _blocksFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshLines();
  }

  void _refreshLines() {
    _blocksFuture = MushafLayout.getPageBlocks(context, widget.pageNo);
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
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: blocks.map((block) {
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
                        );
                      }).toList(),
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

class _AyahRow extends ConsumerWidget {
  final MushafAyahBlock block;
  final double fontSize;
  final ColorScheme colorScheme;

  const _AyahRow({
    required this.block,
    required this.fontSize,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahNo = block.ayahNo ?? 0;
    final badgeSize = 28.0; // Diperbesar dari 22.0 untuk visibility lebih baik
    final settings = ref.watch(settingsProvider);
    final showTajweed = settings.showTajweed && block.tajweed != null && block.tajweed!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AyahBadge(
              ayahNo: ayahNo,
              size: badgeSize,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: showTajweed
                  ? TajweedText(
                      tajweedHtml: block.tajweed!,
                      fontSize: fontSize,
                      defaultColor: colorScheme.onSurface,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      height: 1.8,
                    )
                  : Text(
                      block.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'UthmanicHafsV22',
                        fontFamilyFallback: const ['UthmanicHafs'],
                        fontSize: fontSize,
                        height: 1.8,
                        color: colorScheme.onSurface,
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

    // Style ornament dengan kontras maksimal - background gelap, nomor terang
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Background gelap solid untuk kontras maksimal dengan nomor terang
        color: isDark 
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerHighest,
        // Border tebal dan kontras
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.8),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        // Inner circle dengan background lebih gelap
        width: size * 0.72,
        height: size * 0.72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Background sangat gelap untuk kontras maksimal
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(isDark ? 0.4 : 0.5),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          displayNumber,
          style: TextStyle(
            // Font size lebih besar untuk visibility
            fontSize: size * 0.65,
            height: 1.0,
            fontFamily: 'UthmanicHafsV22',
            fontFamilyFallback: const ['UthmanicHafs'],
            // Warna nomor sangat kontras - gelap di light mode, terang di dark mode
            color: isDark
                ? Colors.white.withOpacity(0.95) // Putih di dark mode
                : Colors.black87, // Hitam gelap di light mode
            fontWeight: FontWeight.w800, // Sangat bold
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

