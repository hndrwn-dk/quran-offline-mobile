import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart' show Verse;
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

void openReaderFromAyahRefs(WidgetRef ref, List<DuaAyahRef> ayahRefs) {
  final primary = ayahRefs.first;
  ref.read(readerSourceProvider.notifier).state =
      SurahSource(primary.surah, targetAyahNo: primary.from);
  ref.read(targetAyahProvider.notifier).state = primary.from;
}

Future<void> showExploreDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String lang,
  required LocalizedText title,
  required LocalizedText summary,
  required List<DuaAyahRef> ayahRefs,
  required VoidCallback onOpenReader,
  LocalizedText? sectionNote,
  String? sectionHeading,
  String? headerArabic,
}) async {
  final db = ref.read(databaseProvider);
  final preloadedVerses = <String, List<Verse>>{};
  for (final ayahRef in ayahRefs) {
    preloadedVerses[ayahRef.rangeKey()] = await db.getVersesByRange(
      ayahRef.surah,
      ayahRef.from,
      ayahRef.to,
    );
  }
  if (!context.mounted) return;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final viewHeight = MediaQuery.sizeOf(sheetContext).height;
      final maxHeight = viewHeight * 0.88;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ExploreDetailSheet(
          maxBodyHeight: maxHeight - 88,
          title: title,
          summary: summary,
          sectionNote: sectionNote,
          sectionHeading: sectionHeading,
          headerArabic: headerArabic,
          ayahRefs: ayahRefs,
          preloadedVerses: preloadedVerses,
          lang: lang,
          onOpenReader: () {
            Navigator.pop(sheetContext);
            onOpenReader();
          },
        ),
      );
    },
  );
}

class ExploreDetailSheet extends ConsumerWidget {
  const ExploreDetailSheet({
    super.key,
    required this.title,
    required this.summary,
    required this.ayahRefs,
    required this.lang,
    required this.onOpenReader,
    this.maxBodyHeight,
    this.preloadedVerses = const {},
    this.sectionNote,
    this.sectionHeading,
    this.headerArabic,
  });

  final LocalizedText title;
  final LocalizedText summary;
  final LocalizedText? sectionNote;
  final String? sectionHeading;
  final List<DuaAyahRef> ayahRefs;
  final Map<String, List<Verse>> preloadedVerses;
  final String lang;
  final VoidCallback onOpenReader;
  final double? maxBodyHeight;
  final String? headerArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final surahNames = ref.watch(surahNamesProvider).valueOrNull ?? [];
    final headerArabicText = headerArabic;
    final headerArabicSize = settings.arabicFontSize * 1.25;

    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headerArabicText != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title.forLanguage(lang),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 112,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          headerArabicText,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontFamily: 'UthmanicHafsV22',
                                fontFamilyFallback: const ['UthmanicHafs'],
                                fontSize: headerArabicSize,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                                color: colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              title.forLanguage(lang),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          const SizedBox(height: 8),
          Text(
            summary.forLanguage(lang),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          if (sectionNote != null && sectionHeading != null) ...[
            const SizedBox(height: 16),
            Text(
              sectionHeading!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              sectionNote!.forLanguage(lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ],
          const SizedBox(height: 20),
          ...ayahRefs.map(
            (ayahRef) => ExploreAyahBlock(
              ayahRef: ayahRef,
              lang: lang,
              surahNames: surahNames,
              verses: preloadedVerses[ayahRef.rangeKey()],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (maxBodyHeight != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxBodyHeight!),
              child: body,
            )
          else
            body,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenReader,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(AppLocalizations.getDuaOpenInReader(lang)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? exploreVerseTranslation(Verse verse, String translationLang) {
  final raw = switch (translationLang) {
    'en' => verse.trEn,
    'id' => verse.trId,
    'zh' => verse.trZh,
    'ja' => verse.trJa,
    _ => verse.trId,
  };
  return raw != null ? TranslationCleaner.clean(raw) : null;
}

class ExploreAyahBlock extends ConsumerWidget {
  const ExploreAyahBlock({
    super.key,
    required this.ayahRef,
    required this.lang,
    required this.surahNames,
    this.verses,
  });

  final DuaAyahRef ayahRef;
  final String lang;
  final List<SurahInfo> surahNames;
  final List<Verse>? verses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final refLabel = AppLocalizations.formatDuaAyahRef(
      ayahRef.surah,
      ayahRef.from,
      ayahRef.to,
      lang,
    );
    SurahInfo? surahInfo;
    for (final s in surahNames) {
      if (s.id == ayahRef.surah) {
        surahInfo = s;
        break;
      }
    }

    final loadedVerses = verses;
    if (loadedVerses == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (surahInfo != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surahInfo.englishName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      if (surahInfo.getMeaning(lang).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            surahInfo.getMeaning(lang),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 128,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.centerRight,
                    child: SurahNameListGlyph(
                      surahId: surahInfo.id,
                      fontSize: 96,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              'Surah ${ayahRef.surah}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          const SizedBox(height: 6),
          Text(
            refLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 14),
          if (loadedVerses.isEmpty)
            Text(
              AppLocalizations.getDuaVerseUnavailable(lang),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...loadedVerses.map(
              (v) => ExploreVersePassage(
                verse: v,
                settings: settings,
                showAyahMarker: loadedVerses.length > 1,
                translationLang: settings.language,
              ),
            ),
        ],
      ),
    );
  }
}

class ExploreVersePassage extends StatelessWidget {
  const ExploreVersePassage({
    super.key,
    required this.verse,
    required this.settings,
    required this.showAyahMarker,
    required this.translationLang,
  });

  final Verse verse;
  final AppSettings settings;
  final bool showAyahMarker;
  final String translationLang;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translation = exploreVerseTranslation(verse, translationLang);
    final arabicSize = settings.arabicFontSize;
    final translationSize = settings.translationFontSize;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showAyahMarker) ...[
            Text(
              '${verse.surahId}:${verse.ayahNo}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.centerRight,
              child: settings.showTajweed &&
                      verse.tajweed != null &&
                      verse.tajweed!.isNotEmpty
                  ? TajweedText(
                      tajweedHtml: verse.tajweed!,
                      fontSize: arabicSize,
                      defaultColor: colorScheme.onSurface,
                      isLightTheme: isLightTheme,
                    )
                  : Localizations.override(
                      context: context,
                      locale: const Locale('ar'),
                      child: SelectableText(
                        verse.tajweed != null && verse.tajweed!.isNotEmpty
                            ? TajweedText.plainArabicFromTajweedHtml(
                                verse.tajweed!,
                              )
                            : TajweedText.normalizeArabicForDisplay(
                                verse.arabic,
                              ),
                        style: TajweedText.arabicDisplayStyle(
                          fontSize: arabicSize,
                          color: colorScheme.onSurface,
                          height: 1.75,
                          isLightTheme: isLightTheme,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
            ),
          ),
          if (translation != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              translation,
              style: TextStyle(
                fontSize: translationSize,
                color: colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
