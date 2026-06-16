import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/tafsir_content.dart';
import 'package:quran_offline/core/models/tafsir_entry.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tafsir_provider.dart';
import 'package:quran_offline/core/tafsir/tafsir_config.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

class AyahTafsirPanel extends ConsumerWidget {
  const AyahTafsirPanel({
    super.key,
    required this.surahId,
    required this.ayahNo,
  });

  final int surahId;
  final int ayahNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (!settings.showTafsir) return const SizedBox.shrink();
    if (TafsirConfig.assetPathForLanguage(settings.language) == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final appLang = settings.appLanguage;
    final mutedColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openTafsirSheet(
              context,
              ref,
              surahId: surahId,
              ayahNo: ayahNo,
              translationLanguage: settings.language,
              appLanguage: appLang,
              fontSize: settings.translationFontSize,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: mutedColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.getTafsirReadAction(appLang),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: mutedColor,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openTafsirSheet(
    BuildContext context,
    WidgetRef ref, {
    required int surahId,
    required int ayahNo,
    required String translationLanguage,
    required String appLanguage,
    required double fontSize,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return _TafsirSheetBody(
              scrollController: scrollController,
              surahId: surahId,
              ayahNo: ayahNo,
              translationLanguage: translationLanguage,
              appLanguage: appLanguage,
              fontSize: fontSize,
            );
          },
        );
      },
    );
  }
}

double _effectiveTafsirFontSize(BuildContext context, double fontSize) {
  final height = MediaQuery.sizeOf(context).height;
  final maxSize = height < 640 ? 18.0 : 24.0;
  return fontSize.clamp(13.0, maxSize);
}

class _TafsirSheetBody extends ConsumerWidget {
  const _TafsirSheetBody({
    required this.scrollController,
    required this.surahId,
    required this.ayahNo,
    required this.translationLanguage,
    required this.appLanguage,
    required this.fontSize,
  });

  final ScrollController scrollController;
  final int surahId;
  final int ayahNo;
  final String translationLanguage;
  final String appLanguage;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tafsirAsync = ref.watch(
      ayahTafsirProvider((
        surahId: surahId,
        ayahNo: ayahNo,
        translationLanguage: translationLanguage,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.getTafsirSheetTitle(
                        appLanguage,
                        surahId,
                        ayahNo,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.getTafsirPanelTitle(appLanguage),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: AppLocalizations.getActionTooltip('close', appLanguage),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant),
        Expanded(
          child: tafsirAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppLocalizations.getTafsirUnavailable(appLanguage),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            data: (entry) {
              if (entry == null || entry.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.getTafsirUnavailable(appLanguage),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }

              final effectiveFontSize =
                  _effectiveTafsirFontSize(context, fontSize);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TafsirMetadataBar(
                    entry: entry,
                    appLanguage: appLanguage,
                    colorScheme: colorScheme,
                  ),
                  Expanded(
                    child: _TafsirSectionsScrollView(
                      scrollController: scrollController,
                      sections: entry.content.sections,
                      fontSize: effectiveFontSize,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TafsirMetadataBar extends StatelessWidget {
  const _TafsirMetadataBar({
    required this.entry,
    required this.appLanguage,
    required this.colorScheme,
  });

  final TafsirEntry entry;
  final String appLanguage;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final revelation = entry.content.revelationType;
    final rangeLabel = entry.rangeLabel;

    if (revelation == null && rangeLabel == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (revelation != null)
              _RevelationChip(
                label: AppLocalizations.getTafsirRevelationLabel(
                  appLanguage,
                  revelation,
                ),
              ),
            if (rangeLabel != null) ...[
              if (revelation != null) const SizedBox(height: 8),
              Text(
                AppLocalizations.getTafsirRangeLabel(appLanguage, rangeLabel),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TafsirSectionsScrollView extends StatelessWidget {
  const _TafsirSectionsScrollView({
    required this.scrollController,
    required this.sections,
    required this.fontSize,
    required this.colorScheme,
  });

  final ScrollController scrollController;
  final List<TafsirSection> sections;
  final double fontSize;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[];

    for (final section in sections) {
      final title = section.title?.trim();
      final hasTitle = title != null && title.isNotEmpty;

      if (hasTitle) {
        slivers.add(
          SliverPersistentHeader(
            pinned: true,
            delegate: _TafsirSectionHeaderDelegate(
              title: title,
              colorScheme: colorScheme,
            ),
          ),
        );
      }

      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, hasTitle ? 8 : 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _TafsirSectionBody(
              section: section,
              fontSize: fontSize,
              includeTitle: !hasTitle,
              colorScheme: colorScheme,
            ),
          ),
        ),
      );
    }

    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 28)));

    return CustomScrollView(
      controller: scrollController,
      slivers: slivers,
    );
  }
}

class _TafsirSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TafsirSectionHeaderDelegate({
    required this.title,
    required this.colorScheme,
  });

  final String title;
  final ColorScheme colorScheme;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: colorScheme.surface,
      elevation: overlapsContent ? 0.5 : 0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TafsirSectionHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _TafsirSectionBody extends StatelessWidget {
  const _TafsirSectionBody({
    required this.section,
    required this.fontSize,
    required this.includeTitle,
    required this.colorScheme,
  });

  final TafsirSection section;
  final double fontSize;
  final bool includeTitle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(
      fontSize: fontSize,
      height: 1.65,
      color: colorScheme.onSurface,
    );
    final labelStyle = bodyStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeTitle &&
            section.title != null &&
            section.title!.trim().isNotEmpty) ...[
          Text(
            section.title!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 10),
        ],
        for (final paragraph in section.paragraphs) ...[
          if (paragraph.label != null)
            RichText(
              text: TextSpan(
                style: bodyStyle,
                children: [
                  TextSpan(text: '${paragraph.label} ', style: labelStyle),
                  TextSpan(text: paragraph.text),
                ],
              ),
            )
          else
            SelectableText(paragraph.text, style: bodyStyle),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RevelationChip extends StatelessWidget {
  const _RevelationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
