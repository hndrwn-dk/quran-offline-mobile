import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/home/widgets/home_cta_buttons.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';
import 'package:quran_offline/features/search/widgets/inset_clamping_scroll.dart';

/// Bold-only highlight: first match only; case-insensitive for text, exact for numbers.
List<TextSpan> searchHighlightSpans(
  String text,
  String query,
  TextStyle normal,
  TextStyle highlight,
) {
  if (query.isEmpty) return [TextSpan(text: text, style: normal)];
  final q = query.trim();
  if (q.isEmpty) return [TextSpan(text: text, style: normal)];
  final isNumeric = int.tryParse(q) != null;
  int start;
  if (isNumeric) {
    start = text.indexOf(q);
  } else {
    start = text.toLowerCase().indexOf(q.toLowerCase());
  }
  if (start == -1) return [TextSpan(text: text, style: normal)];
  final end = start + q.length;
  return [
    if (start > 0) TextSpan(text: text.substring(0, start), style: normal),
    TextSpan(text: text.substring(start, end), style: highlight),
    if (end < text.length) TextSpan(text: text.substring(end), style: normal),
  ];
}

class SearchResultList extends ConsumerWidget {
  const SearchResultList({
    super.key,
    required this.results,
    required this.query,
  });

  final List<SearchResult> results;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InsetClampingScroll(
      builder: (controller) => ListView.builder(
        controller: controller,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return SearchResultTile(
            result: results[index],
            query: query,
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        },
      ),
    );
  }
}

class SearchResultTile extends ConsumerWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.query,
    required this.colorScheme,
    required this.textTheme,
  });

  final SearchResult result;
  final String query;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color? iconColor;

    switch (result.type) {
      case 'surah':
        icon = Icons.book;
        iconColor = Colors.blue;
        break;
      case 'juz':
        icon = Icons.format_list_numbered;
        iconColor = Colors.green;
        break;
      case 'page':
        icon = Icons.pages;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.text_fields;
        iconColor = null;
    }

    final titleStyle = textTheme.titleMedium ?? const TextStyle();
    final subtitleStyle = textTheme.bodySmall ?? const TextStyle();
    final highlightStyle = query.isEmpty
        ? titleStyle
        : titleStyle.copyWith(fontWeight: FontWeight.bold);
    final subtitleHighlightStyle = query.isEmpty
        ? subtitleStyle
        : subtitleStyle.copyWith(fontWeight: FontWeight.bold);

    final isArabicTitle = result.verseMatchKind == SearchVerseMatchKind.arabic;
    final titleAlign = isArabicTitle ? TextAlign.right : TextAlign.start;
    final highlightQuery = isArabicTitle
        ? ArabicSearchNormalizer.normalizeForSearch(query)
        : query;

    Widget titleWidget = query.isEmpty
        ? Text(
            result.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: titleAlign,
          )
        : RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: titleAlign,
            text: TextSpan(
              style: titleStyle.copyWith(
                color: colorScheme.onSurface,
                fontFamily: isArabicTitle ? QuranFonts.digitalKhattV2 : null,
                fontFamilyFallback:
                    isArabicTitle ? QuranFonts.digitalKhattFallbacks : null,
              ),
              children: searchHighlightSpans(
                isArabicTitle
                    ? ArabicSearchNormalizer.normalizeForSearch(result.title)
                    : result.title,
                highlightQuery,
                titleStyle.copyWith(color: colorScheme.onSurface),
                highlightStyle.copyWith(color: colorScheme.onSurface),
              ),
            ),
          );
    if (isArabicTitle) {
      titleWidget = Directionality(
        textDirection: TextDirection.rtl,
        child: titleWidget,
      );
    }
    Widget? subtitleWidget;
    if (result.type == 'surah' && result.source is SurahSource) {
      subtitleWidget = SurahNameSearchGlyph(
        surahId: (result.source as SurahSource).surahId,
      );
    } else if (result.subtitle != null) {
      subtitleWidget = query.isEmpty
          ? Text(
              result.subtitle!,
              style: subtitleStyle,
            )
          : RichText(
              text: TextSpan(
                style: subtitleStyle.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                children: searchHighlightSpans(
                  result.subtitle!,
                  query,
                  subtitleStyle.copyWith(color: colorScheme.onSurfaceVariant),
                  subtitleHighlightStyle.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor?.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: titleWidget,
        subtitle: subtitleWidget,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (result.type == 'page' && result.source is PageSource) {
            final pageSource = result.source as PageSource;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MushafPageView(
                  initialPage: pageSource.pageNo,
                ),
              ),
            );
          } else {
            ref.read(readerSourceProvider.notifier).state = result.source;
            if (result.source is SurahSource) {
              final surahSource = result.source as SurahSource;
              ref.read(targetAyahProvider.notifier).state =
                  surahSource.targetAyahNo;
            } else {
              ref.read(targetAyahProvider.notifier).state = null;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReaderScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}

class TranslationResultsScreen extends ConsumerWidget {
  const TranslationResultsScreen({
    super.key,
    required this.results,
    required this.query,
  });

  final List<SearchResult> results;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const Key('translation_results_screen'),
      backgroundColor: HomeBackdrop.topTint(colorScheme),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: HomeCircleArrowButton.maybeAppBarBack(context),
        backgroundColor: HomeBackdrop.topTint(colorScheme),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
        title: Text(
          AppLocalizations.getAiSearchTranslationJump(lang, results.length),
        ),
      ),
      body: SearchResultList(results: results, query: query),
    );
  }
}
