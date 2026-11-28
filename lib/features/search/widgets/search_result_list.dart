import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          // One grouped card, built lazily: only the first and last rows
          // carry the card's corners, with a hairline between rows.
          return SearchResultTile(
            result: results[index],
            query: query,
            colorScheme: colorScheme,
            textTheme: textTheme,
            isFirst: index == 0,
            isLast: index == results.length - 1,
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
    this.isFirst = true,
    this.isLast = true,
  });

  final SearchResult result;
  final String query;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  /// Position inside a grouped card: the first row rounds the top corners,
  /// the last the bottom ones. A lone tile is a full card.
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;

    switch (result.type) {
      case 'surah':
        icon = Icons.book;
        break;
      case 'juz':
        icon = Icons.format_list_numbered;
        break;
      case 'page':
        icon = Icons.pages;
        break;
      default:
        icon = Icons.text_fields;
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

    const radius = Radius.circular(20);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? radius : Radius.zero,
        bottom: isLast ? radius : Radius.zero,
      ),
    );
    return Material(
      color: colorScheme.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFirst)
            Divider(
              height: 1,
              thickness: 1,
              indent: 60,
              color: colorScheme.hairline,
            ),
          _buildTile(context, ref, icon, titleWidget, subtitleWidget),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    Widget titleWidget,
    Widget? subtitleWidget,
  ) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        horizontalTitleGap: 12,
        minLeadingWidth: 32,
        leading: AppBadge(icon: icon),
        title: titleWidget,
        subtitle: subtitleWidget,
        trailing: Icon(
          Icons.chevron_right,
          size: 22,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
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
      body: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SearchResultList(results: results, query: query),
      ),
    );
  }
}
