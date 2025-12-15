import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/features/reader/ayah_card.dart';
import 'package:quran_offline/features/reader/surah_header_card.dart';
import 'package:quran_offline/features/reader/text_settings_dialog.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(readerSourceProvider);
    final isLargeScreen = Responsive.isLargeScreen(context);
    final surahsAsync = ref.watch(surahNamesProvider);
    
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

    // Minimal AppBar - no title, just back button and text settings + subtle divider
    final appBar = isLargeScreen
        ? null
        : AppBar(
            leading: Navigator.canPop(context) ? const BackButton() : null,
            automaticallyImplyLeading: false,
            toolbarHeight: 54,
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

    return Scaffold(
      appBar: appBar,
      body: versesAsync.when(
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

                  return ListView.builder(
                    padding: EdgeInsets.zero,
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                          child: SurahHeaderCard(
                            surahInfo: surahInfo,
                            verseCount: verses.where((v) => v.surahId == verse.surahId).length,
                          ),
                            ),
                          ],
                          // Show Bismillah before first ayah of each surah (except Surah 1 and Surah 9)
                          // Note: Surah 1's first ayah IS the Bismillah, so we don't show it separately
                          if (isFirstAyah && Bismillah.shouldShowBismillah(verse.surahId)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Align(
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
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(
                                height: 1,
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                AyahCard(verse: verse),
                                Divider(
                                  height: 1,
                                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
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
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              padding: const EdgeInsets.only(top: 24, bottom: 16),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ],
                          if (showSurahDivider) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ],
                          if (isFirstAyah && Bismillah.shouldShowBismillah(verse.surahId)) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                top: (isSurahSource && isFirstVerse) ? 24 : 0,
                                bottom: 16,
                              ),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Align(
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
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                            ),
                          ],
                          AyahCard(verse: verse),
                          Divider(
                            height: 1,
                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                        ],
                      );
                    },
                  );
                },
                error: (_, __) {
                  final settings = ref.watch(settingsProvider);
                  final isSurahSource = source is SurahSource;
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              padding: const EdgeInsets.only(top: 24, bottom: 16),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ],
                          if (showSurahDivider) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Surah ${verse.surahId}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ],
                          if (isFirstAyah && Bismillah.shouldShowBismillah(verse.surahId)) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                top: (isSurahSource && isFirstVerse) ? 24 : 0,
                                bottom: 16,
                              ),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Align(
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
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                            ),
                          ],
                          AyahCard(verse: verse),
                          Divider(
                            height: 1,
                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
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
    );
  }


}



