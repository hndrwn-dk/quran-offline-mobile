import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Page ${widget.pageNo}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                      ),
                    ],
                  );
                }

                // Format subtitle: "Surah X–Y" or "N surah"
                String subtitle;
                if (surahIds.length == 1) {
                  final surah = surahs.firstWhere(
                    (s) => s.id == surahIds.first,
                    orElse: () => SurahInfo(
                      id: surahIds.first,
                      arabicName: '',
                      englishName: 'Surah ${surahIds.first}',
                      englishMeaning: '',
                    ),
                  );
                  subtitle = 'Surah ${surah.id}';
                } else if (surahIds.length == 2) {
                  subtitle = 'Surah ${surahIds.first}–${surahIds.last}';
                } else {
                  subtitle = '${surahIds.length} surah';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${widget.pageNo}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page ${widget.pageNo}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page ${widget.pageNo}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ],
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                block.text,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontFamily: 'UthmanicHafsV22',
                                      fontFamilyFallback: const ['UthmanicHafs'],
                                      fontSize: fontSize + 2,
                                      height: 1.7,
                                      color: colorScheme.onSurface,
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

class _AyahRow extends StatelessWidget {
  final MushafAyahBlock block;
  final double fontSize;
  final ColorScheme colorScheme;

  const _AyahRow({
    required this.block,
    required this.fontSize,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final ayahNo = block.ayahNo ?? 0;
    final badgeSize = 22.0;

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
              child: Text(
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        displayNumber,
        style: TextStyle(
          fontSize: size * 0.55,
          height: 1.0,
          fontFamily: 'UthmanicHafsV22',
          fontFamilyFallback: const ['UthmanicHafs'],
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

