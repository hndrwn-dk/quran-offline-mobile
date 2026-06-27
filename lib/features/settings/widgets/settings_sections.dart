import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/package_info_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/tajweed/tajweed_report.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/tajweed_color_guide.dart';
import 'package:quran_offline/features/settings/audio_downloads_screen.dart';
import 'package:quran_offline/features/settings/settings_link_actions.dart';
import 'package:quran_offline/features/settings/widgets/about_data_sources_tile.dart';

String settingsTransliterationSubtitle(AppSettings settings, String appLanguage) {
  if (settings.useTajweedTransliteration) {
    return AppLocalizations.getSettingsText(
      'transliteration_source_tajweed_sub',
      appLanguage,
    );
  }
  return AppLocalizations.getSettingsText(
    'transliteration_source_simple_sub',
    appLanguage,
  );
}

String settingsLanguageName(String lang) {
  return switch (lang) {
    'id' => 'Indonesian',
    'en' => 'English',
    'zh' => 'Chinese',
    'ja' => 'Japanese',
    _ => lang,
  };
}

String settingsThemeModeName(ThemeMode mode, String language) {
  return switch (mode) {
    ThemeMode.system => AppLocalizations.getSettingsText('theme_system', language),
    ThemeMode.light => AppLocalizations.getSettingsText('theme_light', language),
    ThemeMode.dark => AppLocalizations.getSettingsText('theme_dark', language),
  };
}

IconData settingsThemeModeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
    ThemeMode.system => Icons.brightness_auto,
  };
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class SettingsQuranSection extends ConsumerWidget {
  const SettingsQuranSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: AppLocalizations.getSettingsText('quran_settings_header', appLanguage),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.language, color: colorScheme.primary),
            title: Text(AppLocalizations.getSettingsText('language_title', appLanguage)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settingsLanguageName(settings.language),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  AppLocalizations.getSettingsText('language_subtitle', appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            childrenPadding: EdgeInsets.zero,
            children: ['id', 'en', 'zh', 'ja'].map((lang) {
              final descKey = switch (lang) {
                'id' => 'language_indonesian_desc',
                'en' => 'language_english_desc',
                'zh' => 'language_chinese_desc',
                'ja' => 'language_japanese_desc',
                _ => 'language_indonesian_desc',
              };
              return ListTile(
                leading: Icon(
                  Icons.translate,
                  color: settings.language == lang
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                title: Text(settingsLanguageName(lang)),
                subtitle: Text(
                  AppLocalizations.getSettingsText(descKey, appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
                trailing: Radio<String>(
                  value: lang,
                  groupValue: settings.language,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateLocale(value);
                    }
                  },
                ),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () {
                  ref.read(settingsProvider.notifier).updateLocale(lang);
                },
              );
            }).toList(),
          ),
        ),
        ListTile(
          leading: Icon(Icons.text_fields, color: colorScheme.primary),
          title: Text(
            AppLocalizations.getSettingsText('show_transliteration_title', appLanguage),
          ),
          subtitle: Text(
            AppLocalizations.getSettingsText('show_transliteration_subtitle', appLanguage),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          trailing: Switch(
            value: settings.showTransliteration,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTransliteration(value);
            },
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.record_voice_over, color: colorScheme.primary),
            title: Text(
              AppLocalizations.getSettingsText('transliteration_choice_title', appLanguage),
            ),
            subtitle: Text(
              settingsTransliterationSubtitle(settings, appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [
              RadioListTile<bool>(
                title: Text(
                  AppLocalizations.getSettingsText(
                    'transliteration_source_tajweed',
                    appLanguage,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.getSettingsText(
                    'transliteration_source_tajweed_sub',
                    appLanguage,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                value: true,
                groupValue: settings.useTajweedTransliteration,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).updateUseTajweedTransliteration(v);
                  }
                },
              ),
              RadioListTile<bool>(
                title: Text(
                  AppLocalizations.getSettingsText(
                    'transliteration_source_simple',
                    appLanguage,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.getSettingsText(
                    'transliteration_source_simple_sub',
                    appLanguage,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                value: false,
                groupValue: settings.useTajweedTransliteration,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).updateUseTajweedTransliteration(v);
                  }
                },
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.translate, color: colorScheme.primary),
          title: Text(
            AppLocalizations.getSettingsText('show_translation_title', appLanguage),
          ),
          subtitle: Text(
            AppLocalizations.getSettingsText('show_translation_subtitle', appLanguage),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          trailing: Switch(
            value: settings.showTranslation,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTranslation(value);
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.menu_book_outlined, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('show_tafsir_title', appLanguage)),
          subtitle: Text(
            AppLocalizations.getSettingsText('show_tafsir_subtitle', appLanguage),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          trailing: Switch(
            value: settings.showTafsir,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTafsir(value);
            },
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.color_lens, color: colorScheme.primary),
            title: Text(AppLocalizations.getSettingsText('show_tajweed_title', appLanguage)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.getSettingsText('show_tajweed_subtitle', appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.getSettingsText('tajweed_guide_intro', appLanguage),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: settings.showTajweed,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updateShowTajweed(value);
              },
            ),
            childrenPadding: const EdgeInsets.fromLTRB(72, 8, 16, 16),
            children: [
              TajweedColorGuideContent(appLanguage: appLanguage),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsRecitationSection extends ConsumerWidget {
  const SettingsRecitationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final selected = ref.watch(reciterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: AppLocalizations.getRecitationText('recitation_section', appLanguage),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.headphones, color: colorScheme.primary),
            title: Text(AppLocalizations.getRecitationText('reciter', appLanguage)),
            subtitle: Text(
              selected.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            childrenPadding: EdgeInsets.zero,
            children: ReciterCatalog.reciters.map((reciter) {
              return RadioListTile<String>(
                value: reciter.id,
                groupValue: selected.id,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(reciterProvider.notifier).select(ReciterCatalog.byId(value));
                  }
                },
                title: Text(reciter.name),
                subtitle: Text(
                  '${reciter.arabicName}  -  ${reciter.bitrate} kbps',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                dense: true,
              );
            }).toList(),
          ),
        ),
        Builder(
          builder: (context) {
            final reciter = ref.watch(reciterProvider);
            final downloads = ref.watch(audioDownloadProvider);
            final saved = downloads.completed
                .where((k) => k.startsWith('${reciter.id}:'))
                .length;
            return ListTile(
              leading: Icon(Icons.download_for_offline_outlined, color: colorScheme.primary),
              title: Text(
                AppLocalizations.getRecitationText('save_recitation_audio', appLanguage),
              ),
              subtitle: Text(
                saved >= AudioOfflinePrompts.totalSurahs
                    ? AppLocalizations.recAllSavedFor(reciter.name, appLanguage)
                    : AppLocalizations.recSavedForReciterShort(
                        saved,
                        AudioOfflinePrompts.totalSurahs,
                        reciter.name,
                        appLanguage,
                      ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AudioDownloadsScreen(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class SettingsAppSection extends ConsumerWidget {
  const SettingsAppSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: AppLocalizations.getSettingsText('app_settings_header', appLanguage),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.palette, color: colorScheme.primary),
            title: Text(AppLocalizations.getSettingsText('theme_title', appLanguage)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settingsThemeModeName(settings.themeMode, appLanguage)),
                Text(
                  AppLocalizations.getSettingsText('theme_subtitle', appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            childrenPadding: EdgeInsets.zero,
            children: ThemeMode.values.map((mode) {
              final descKey = switch (mode) {
                ThemeMode.system => 'theme_system_desc',
                ThemeMode.light => 'theme_light_desc',
                ThemeMode.dark => 'theme_dark_desc',
              };
              return ListTile(
                leading: Icon(
                  settingsThemeModeIcon(mode),
                  color: settings.themeMode == mode
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                title: Text(settingsThemeModeName(mode, appLanguage)),
                subtitle: Text(
                  AppLocalizations.getSettingsText(descKey, appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
                trailing: Radio<ThemeMode>(
                  value: mode,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateThemeMode(value);
                    }
                  },
                ),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () {
                  ref.read(settingsProvider.notifier).updateThemeMode(mode);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SettingsAboutAppSection extends ConsumerWidget {
  const SettingsAboutAppSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: AppLocalizations.getSettingsText('about_app_section', appLanguage),
        ),
        ListTile(
          leading: Icon(Icons.info_outline, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('version_title', appLanguage)),
          subtitle: ref.watch(packageInfoProvider).when(
                data: (info) => Text('${info.version} (${info.buildNumber})'),
                loading: () => const Text('…'),
                error: (_, __) => const Text('—'),
              ),
        ),
        ListTile(
          leading: Icon(Icons.star_outline, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('rate_app_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('rate_app_subtitle', appLanguage)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SettingsLinkActions.openRateApp(context, appLanguage),
        ),
        ListTile(
          leading: Icon(Icons.share_outlined, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('share_app_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('share_app_subtitle', appLanguage)),
          onTap: () => SettingsLinkActions.shareApp(appLanguage),
        ),
      ],
    );
  }
}

class SettingsAboutSupportSection extends ConsumerWidget {
  const SettingsAboutSupportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: AppLocalizations.getSettingsText('about_support_section', appLanguage),
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('support_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('support_subtitle', appLanguage)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SettingsLinkActions.openDonate(context),
          onLongPress: () => SettingsLinkActions.showSupportInfo(context, ref),
        ),
      ],
    );
  }
}

class SettingsAboutLegalSection extends ConsumerWidget {
  const SettingsAboutLegalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: AppLocalizations.getSettingsText('about_legal_section', appLanguage),
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('privacy_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('privacy_subtitle', appLanguage)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SettingsLinkActions.openPrivacy(context),
        ),
        ListTile(
          leading: Icon(Icons.description, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('terms_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('terms_subtitle', appLanguage)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SettingsLinkActions.openTerms(context),
        ),
        AboutDataSourcesTile(appLanguage: appLanguage),
      ],
    );
  }
}

class SettingsAboutFeedbackSection extends ConsumerWidget {
  const SettingsAboutFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: AppLocalizations.getSettingsText('about_feedback_section', appLanguage),
        ),
        ListTile(
          leading: Icon(Icons.bug_report, color: colorScheme.primary),
          title: Text(AppLocalizations.getSettingsText('report_tajweed_title', appLanguage)),
          onTap: () {
            final lastAyah = TajweedReport.ayahFromLastRead(ref.read(lastReadProvider));
            TajweedReport.launch(
              context: context,
              language: appLanguage,
              surahId: lastAyah?.surahId,
              ayahNo: lastAyah?.ayahNo,
            );
          },
        ),
      ],
    );
  }
}
