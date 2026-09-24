import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart' show Verse;
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/models/surah_qul_info.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/quran_dua_ayat_catalog_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/surah_qul_info_provider.dart';
import 'package:quran_offline/core/providers/tafsir_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

bool aiSearchShowsKurasiBadge(String type) =>
    type == 'science' || type == 'theme';

String aiSearchSourceRef(AiSearchHit hit, String lang) {
  switch (hit.type) {
    case 'tafsir':
      if (hit.surah != null && hit.ayahFrom != null) {
        return AppLocalizations.getAiSearchTafsirSource(
          lang,
          hit.surah!,
          hit.ayahFrom!,
        );
      }
      return hit.refKey;
    case 'asma':
      return AppLocalizations.getAiSearchAsmaSource(lang, hit.refKey);
    case 'surah_info':
      final surah = hit.surah ?? int.tryParse(hit.refKey);
      if (surah != null) {
        return AppLocalizations.getAiSearchSurahSource(lang, surah);
      }
      return hit.refKey;
    default:
      if (hit.surah != null && hit.ayahFrom != null) {
        return AppLocalizations.formatDuaAyahRef(
          hit.surah!,
          hit.ayahFrom!,
          hit.ayahTo ?? hit.ayahFrom!,
          lang,
        );
      }
      return hit.refKey;
  }
}

String _clip(String text, [int max = 140]) {
  final trimmed = text.trim();
  if (trimmed.length <= max) return trimmed;
  return '${trimmed.substring(0, max).trim()}...';
}

String _verseTranslation(Verse verse, String lang) {
  final raw = switch (lang) {
    'en' => verse.trEn ?? verse.trId ?? '',
    'zh' => verse.trZh ?? verse.trEn ?? '',
    'ja' => verse.trJa ?? verse.trEn ?? '',
    _ => verse.trId ?? verse.trEn ?? '',
  };
  return TranslationCleaner.clean(raw);
}

Future<String> resolveAiSearchTitle({
  required WidgetRef ref,
  required AiSearchHit hit,
  required String lang,
}) async {
  final fallback = aiSearchSourceRef(hit, lang);
  try {
    switch (hit.type) {
      case 'ayah':
        if (hit.surah == null || hit.ayahFrom == null) return fallback;
        final verse = await ref.read(databaseProvider).getVerse(
              hit.surah!,
              hit.ayahFrom!,
            );
        if (verse == null) return fallback;
        final text = _verseTranslation(verse, lang);
        return text.isEmpty ? fallback : _clip(text);
      case 'tafsir':
        if (hit.surah == null || hit.ayahFrom == null) return fallback;
        final entry = await ref.read(
          ayahTafsirProvider((
            surahId: hit.surah!,
            ayahNo: hit.ayahFrom!,
            translationLanguage: lang,
          )).future,
        );
        final text = entry?.plainText.trim() ?? '';
        return text.isEmpty ? fallback : _clip(text);
      case 'surah_info':
        final surahId = hit.surah ?? int.tryParse(hit.refKey);
        if (surahId == null) return fallback;
        final info = await ref.read(
          surahQulInfoForSurahProvider((
            surahId: surahId,
            lang: qulSurahInfoLanguage(lang),
          )).future,
        );
        final short = info?.short.trim() ?? '';
        if (short.isNotEmpty) return _clip(short);
        final names = await ref.read(surahNamesProvider.future);
        for (final s in names) {
          if (s.id == surahId && s.englishName.isNotEmpty) {
            return s.englishName;
          }
        }
        return fallback;
      case 'dua':
        final catalog = await ref.read(duaCatalogProvider.future);
        for (final e in catalog.entries) {
          if (e.id == hit.refKey) return e.title.forLanguage(lang);
        }
        return fallback;
      case 'science':
        final catalog = await ref.read(scienceCatalogProvider.future);
        for (final e in catalog.entries) {
          if (e.id == hit.refKey) return e.title.forLanguage(lang);
        }
        return fallback;
      case 'theme':
        final catalog = await ref.read(themeCatalogProvider.future);
        for (final e in catalog.entries) {
          if (e.id == hit.refKey) return e.title.forLanguage(lang);
        }
        return fallback;
      case 'asma':
        final catalog = await ref.read(asmaCatalogProvider.future);
        final number = int.tryParse(hit.refKey);
        for (final e in catalog.entries) {
          if (e.id == hit.refKey || (number != null && e.number == number)) {
            return e.title.forLanguage(lang);
          }
        }
        return fallback;
      case 'quran_dua':
        final catalog = await ref.read(quranDuaAyatCatalogProvider.future);
        for (final e in catalog.entries) {
          if (e.id == hit.refKey) {
            return lang == 'id' ? e.need.id : e.need.en;
          }
        }
        return fallback;
      default:
        return fallback;
    }
  } catch (_) {
    return fallback;
  }
}

Future<void> openAiSearchHit({
  required BuildContext context,
  required WidgetRef ref,
  required AiSearchHit hit,
  required String lang,
}) async {
  switch (hit.type) {
    case 'dua':
      final catalog = await ref.read(duaCatalogProvider.future);
      DuaEntry? entry;
      for (final e in catalog.entries) {
        if (e.id == hit.refKey) entry = e;
      }
      if (entry == null || !context.mounted) return;
      await showExploreDetailSheet(
        context: context,
        ref: ref,
        lang: lang,
        title: entry.title,
        summary: entry.summary,
        ayahRefs: entry.ayahRefs,
        onOpenReader: (ayahRef) {
          openReaderFromAyahRef(ref, ayahRef);
          openReaderScreen(context, ref);
        },
      );
      return;
    case 'science':
      final catalog = await ref.read(scienceCatalogProvider.future);
      for (final e in catalog.entries) {
        if (e.id != hit.refKey) continue;
        if (!context.mounted) return;
        await showExploreDetailSheet(
          context: context,
          ref: ref,
          lang: lang,
          title: e.title,
          summary: e.summary,
          sectionNote: e.scienceNote,
          sectionHeading: AppLocalizations.getScienceNoteHeading(lang),
          ayahRefs: e.ayahRefs,
          onOpenReader: (ayahRef) {
            openReaderFromAyahRef(ref, ayahRef);
            openReaderScreen(context, ref);
          },
        );
        return;
      }
      return;
    case 'theme':
      final catalog = await ref.read(themeCatalogProvider.future);
      for (final e in catalog.entries) {
        if (e.id != hit.refKey) continue;
        if (!context.mounted) return;
        await showExploreDetailSheet(
          context: context,
          ref: ref,
          lang: lang,
          title: e.title,
          summary: e.summary,
          sectionNote: e.reflection,
          sectionHeading: AppLocalizations.getThemeReflectionHeading(lang),
          ayahRefs: e.ayahRefs,
          onOpenReader: (ayahRef) {
            openReaderFromAyahRef(ref, ayahRef);
            openReaderScreen(context, ref);
          },
        );
        return;
      }
      return;
    case 'asma':
      final catalog = await ref.read(asmaCatalogProvider.future);
      final number = int.tryParse(hit.refKey);
      for (final e in catalog.entries) {
        if (e.id != hit.refKey && (number == null || e.number != number)) {
          continue;
        }
        if (!context.mounted) return;
        await showExploreDetailSheet(
          context: context,
          ref: ref,
          lang: lang,
          title: e.title,
          summary: e.summary,
          sectionNote: e.reflection,
          sectionHeading: AppLocalizations.getAsmaReflectionHeading(lang),
          headerArabic: e.arabic,
          ayahRefs: e.ayahRefs,
          onOpenReader: (ayahRef) {
            openReaderFromAyahRef(ref, ayahRef);
            openReaderScreen(context, ref);
          },
        );
        return;
      }
      return;
    default:
      await _openHitInReader(context, ref, hit);
  }
}

Future<void> _openHitInReader(
  BuildContext context,
  WidgetRef ref,
  AiSearchHit hit,
) async {
  final surah = hit.surah ?? int.tryParse(hit.refKey);
  if (surah == null) return;
  ref.read(readerSourceProvider.notifier).state = SurahSource(
    surah,
    targetAyahNo: hit.ayahFrom,
  );
  ref.read(targetAyahProvider.notifier).state = hit.ayahFrom;
  await openReaderScreen(context, ref);
}

/// Presentational card: type, original-source title, source ref, optional kurasi.
class AiResultCard extends StatelessWidget {
  const AiResultCard({
    super.key,
    required this.typeLabel,
    required this.title,
    required this.sourceRef,
    required this.showKurasiBadge,
    this.kurasiBadgeLabel,
    this.onTap,
  });

  final String typeLabel;
  final String title;
  final String sourceRef;
  final bool showKurasiBadge;
  final String? kurasiBadgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              typeLabel,
              key: const Key('ai_result_type'),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sourceRef,
              key: const Key('ai_result_source'),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (showKurasiBadge && kurasiBadgeLabel != null) ...[
              const SizedBox(height: 6),
              Container(
                key: const Key('ai_kurasi_badge'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kurasiBadgeLabel!,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Loads title from original sources (never body_norm) and opens the destination.
class AiSearchHitCard extends ConsumerStatefulWidget {
  const AiSearchHitCard({
    super.key,
    required this.hit,
    required this.lang,
  });

  final AiSearchHit hit;
  final String lang;

  @override
  ConsumerState<AiSearchHitCard> createState() => _AiSearchHitCardState();
}

class _AiSearchHitCardState extends ConsumerState<AiSearchHitCard> {
  late Future<String> _titleFuture;

  @override
  void initState() {
    super.initState();
    _titleFuture = resolveAiSearchTitle(
      ref: ref,
      hit: widget.hit,
      lang: widget.lang,
    );
  }

  @override
  void didUpdateWidget(covariant AiSearchHitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hit.docId != widget.hit.docId ||
        oldWidget.lang != widget.lang) {
      _titleFuture = resolveAiSearchTitle(
        ref: ref,
        hit: widget.hit,
        lang: widget.lang,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceRef = aiSearchSourceRef(widget.hit, widget.lang);
    final typeLabel = AppLocalizations.getAiSearchTypeLabel(
      widget.hit.type,
      widget.lang,
    );
    final showKurasi = aiSearchShowsKurasiBadge(widget.hit.type);
    return FutureBuilder<String>(
      future: _titleFuture,
      builder: (context, snapshot) {
        return AiResultCard(
          typeLabel: typeLabel,
          title: snapshot.data ?? sourceRef,
          sourceRef: sourceRef,
          showKurasiBadge: showKurasi,
          kurasiBadgeLabel: showKurasi
              ? AppLocalizations.getAiSearchKurasiBadge(widget.lang)
              : null,
          onTap: () => openAiSearchHit(
            context: context,
            ref: ref,
            hit: widget.hit,
            lang: widget.lang,
          ),
        );
      },
    );
  }
}
