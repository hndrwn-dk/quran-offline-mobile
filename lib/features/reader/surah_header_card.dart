import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/surah_qul_info.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/surah_qul_info_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/reader/widgets/recitation_controls.dart';

/// QUL surah header: name font v2 + surah info (follows translation language).
class SurahHeaderCard extends ConsumerWidget {
  const SurahHeaderCard({
    super.key,
    required this.surahInfo,
    required this.verseCount,
  });

  final SurahInfo surahInfo;
  final int verseCount;

  static bool _isMeccan(int surahId) {
    const medinanSurahs = {
      2, 3, 4, 5, 8, 9, 13, 22, 24, 33, 47, 48, 49, 57, 58, 59, 60, 61, 62,
      63, 64, 65, 66, 98,
    };
    return !medinanSurahs.contains(surahId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;
    final qulLang = qulSurahInfoLanguage(settings.language);
    final colorScheme = Theme.of(context).colorScheme;
    final isMeccan = _isMeccan(surahInfo.id);
    final qulAsync = ref.watch(
      surahQulInfoForSurahProvider((surahId: surahInfo.id, lang: qulLang)),
    );

    return Container(
      key: const Key('surah_header_card'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '#${surahInfo.id}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: SurahNameGlyph(
              surahId: surahInfo.id,
              fontSize: 52,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            surahInfo.englishName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          if (surahInfo.englishMeaning.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              surahInfo.getMeaning(lang),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetaChip(
                label: isMeccan
                    ? AppLocalizations.getSurahMetaMeccan(lang)
                    : AppLocalizations.getSurahMetaMedinan(lang),
                color: isMeccan
                    ? colorScheme.primaryContainer
                    : colorScheme.secondaryContainer,
                fg: isMeccan
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                label: AppLocalizations.formatSurahVerseCount(lang, verseCount),
                color: colorScheme.surfaceContainerHighest,
                fg: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SurahRecitationControls(
            surahId: surahInfo.id,
            surahName: surahInfo.englishName,
            verseCount: verseCount,
          ),
          const SizedBox(height: 12),
          qulAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              AppLocalizations.getSurahHeaderQulInfoError(lang),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
            data: (entry) {
              if (entry == null || entry.isEmpty) {
                return Text(
                  AppLocalizations.getSurahHeaderQulInfoMissing(lang),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.getSurahHeaderAboutSurah(lang),
                    key: const Key('surah_header_about_surah'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  _QulInfoLangPanel(
                    langCode: qulLang,
                    entry: entry,
                    uiLang: lang,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    required this.fg,
  });

  final String label;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _QulInfoLangPanel extends StatelessWidget {
  const _QulInfoLangPanel({
    required this.langCode,
    required this.entry,
    required this.uiLang,
  });

  final String langCode;
  final SurahQulInfoEntry entry;
  final String uiLang;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = langCode == 'id'
        ? AppLocalizations.getSurahHeaderLangIndonesian(uiLang)
        : AppLocalizations.getSurahHeaderLangEnglish(uiLang);

    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          height: 1.45,
        );
    final supplementaryStyle = bodyStyle?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
          if (entry.short.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(entry.short, style: bodyStyle),
          ],
          if (entry.supplementaryBody.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(entry.supplementaryBody, style: supplementaryStyle),
          ],
          if (entry.sections.isNotEmpty) ...[
            if (entry.short.isNotEmpty || entry.supplementaryBody.isNotEmpty)
              const SizedBox(height: 4),
            for (final section in entry.sections)
              _SurahInfoSectionTile(
                title: section.title,
                body: section.body,
                colorScheme: colorScheme,
              ),
          ],
        ],
      ),
    );
  }
}

class _SurahInfoSectionTile extends StatefulWidget {
  const _SurahInfoSectionTile({
    required this.title,
    required this.body,
    required this.colorScheme,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;

  @override
  State<_SurahInfoSectionTile> createState() => _SurahInfoSectionTileState();
}

class _SurahInfoSectionTileState extends State<_SurahInfoSectionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          height: 1.45,
          color: widget.colorScheme.onSurfaceVariant,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: titleStyle),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: widget.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.body, style: bodyStyle),
            ),
          ),
      ],
    );
  }
}
