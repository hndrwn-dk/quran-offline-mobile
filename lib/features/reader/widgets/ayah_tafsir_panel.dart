import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/tafsir_content.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 4),
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
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.getTafsirReadAction(appLang),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  if (entry.content.revelationType != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RevelationChip(
                        label: entry.content.revelationType!,
                      ),
                    ),
                  if (entry.rangeLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        AppLocalizations.getTafsirRangeLabel(
                          appLanguage,
                          entry.rangeLabel!,
                        ),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ...entry.content.sections.map(
                    (section) => _TafsirSectionView(
                      section: section,
                      fontSize: fontSize,
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

class _TafsirSectionView extends StatelessWidget {
  const _TafsirSectionView({
    required this.section,
    required this.fontSize,
  });

  final TafsirSection section;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(
      fontSize: fontSize,
      height: 1.65,
      color: colorScheme.onSurface,
    );
    final labelStyle = bodyStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title != null && section.title!.trim().isNotEmpty) ...[
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
      ),
    );
  }
}
