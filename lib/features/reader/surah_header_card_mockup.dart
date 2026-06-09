import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/surah_qul_info.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/surah_qul_info_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/reader/widgets/recitation_controls.dart';

/// QUL preview header: Surah name font v2 + EN/ID surah info (no ZH/JA).
class SurahHeaderCardMockup extends ConsumerWidget {
  const SurahHeaderCardMockup({
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
    final qulAsync = ref.watch(surahQulInfoProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.getSurahHeaderQulPreviewBadge(lang),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                '#${surahInfo.id}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 16),
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
            data: (bundle) {
              final entry = bundle.forSurah(surahInfo.id, qulLang);
              if (entry == null) {
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
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
            const SizedBox(height: 8),
            Text(
              entry.short,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
            ),
          ],
          for (final section in entry.sections) ...[
            const SizedBox(height: 6),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  section.title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      section.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
