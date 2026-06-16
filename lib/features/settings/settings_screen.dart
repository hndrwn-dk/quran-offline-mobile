import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/package_info_provider.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/settings/audio_downloads_screen.dart';
import 'package:quran_offline/core/widgets/tajweed_color_guide.dart';
import 'package:quran_offline/core/tajweed/tajweed_report.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/features/settings/widgets/about_data_sources_tile.dart';

String _transliterationSubtitle(AppSettings settings, String appLanguage) {
  if (settings.useTajweedTransliteration) {
    return AppLocalizations.getSettingsText('transliteration_source_tajweed_sub', appLanguage);
  }
  return AppLocalizations.getSettingsText('transliteration_source_simple_sub', appLanguage);
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.getSettingsText('settings_title', appLanguage),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.getSubtitleText('settings_subtitle', appLanguage),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBackButton) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 2),
            ],
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.tune,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            titleColumn,
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      body: ListView(
        children: [
          // Qur'an Settings section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              AppLocalizations.getSettingsText('quran_settings_header', appLanguage),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              leading: Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(AppLocalizations.getSettingsText('language_title', appLanguage)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLanguageName(settings.language),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    AppLocalizations.getSettingsText('language_subtitle', appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    _getLanguageIcon(lang),
                    color: settings.language == lang
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  title: Text(_getLanguageName(lang)),
                  subtitle: Text(
                    AppLocalizations.getSettingsText(descKey, appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            leading: Icon(
              Icons.text_fields,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.getSettingsText('show_transliteration_title', appLanguage)),
            subtitle: Text(
              AppLocalizations.getSettingsText('show_transliteration_subtitle', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              leading: Icon(
                Icons.record_voice_over,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(AppLocalizations.getSettingsText('transliteration_choice_title', appLanguage)),
              subtitle: Text(
                _transliterationSubtitle(settings, appLanguage),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              childrenPadding: EdgeInsets.zero,
              children: [
                RadioListTile<bool>(
                  title: Text(AppLocalizations.getSettingsText('transliteration_source_tajweed', appLanguage)),
                  subtitle: Text(
                    AppLocalizations.getSettingsText('transliteration_source_tajweed_sub', appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: true,
                  groupValue: settings.useTajweedTransliteration,
                  onChanged: (v) {
                    if (v != null) ref.read(settingsProvider.notifier).updateUseTajweedTransliteration(v);
                  },
                ),
                RadioListTile<bool>(
                  title: Text(AppLocalizations.getSettingsText('transliteration_source_simple', appLanguage)),
                  subtitle: Text(
                    AppLocalizations.getSettingsText('transliteration_source_simple_sub', appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: false,
                  groupValue: settings.useTajweedTransliteration,
                  onChanged: (v) {
                    if (v != null) ref.read(settingsProvider.notifier).updateUseTajweedTransliteration(v);
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.translate,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.getSettingsText('show_translation_title', appLanguage)),
            subtitle: Text(
              AppLocalizations.getSettingsText('show_translation_subtitle', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            leading: Icon(
              Icons.menu_book_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.getSettingsText('show_tafsir_title', appLanguage)),
            subtitle: Text(
              AppLocalizations.getSettingsText('show_tafsir_subtitle', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              leading: Icon(
                Icons.color_lens,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(AppLocalizations.getSettingsText('show_tajweed_title', appLanguage)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.getSettingsText('show_tajweed_subtitle', appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppLocalizations.getSettingsText('tajweed_guide_intro', appLanguage),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                TajweedColorGuideContent(
                  appLanguage: appLanguage,
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.flag_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              AppLocalizations.getSettingsText('report_tajweed_title', appLanguage),
            ),
            subtitle: Text(
              AppLocalizations.getSettingsText('report_tajweed_subtitle', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
          const Divider(),
          // Recitation section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              AppLocalizations.getRecitationText('recitation_section', appLanguage),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildReciterTile(context, ref),
          Builder(
            builder: (context) {
              final reciter = ref.watch(reciterProvider);
              final downloads = ref.watch(audioDownloadProvider);
              final saved = downloads.completed
                  .where((k) => k.startsWith('${reciter.id}:'))
                  .length;
              return ListTile(
                leading: Icon(
                  Icons.download_for_offline_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                    MaterialPageRoute(
                      builder: (_) => const AudioDownloadsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(),
          // App Settings section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              AppLocalizations.getSettingsText('app_settings_header', appLanguage),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              leading: Icon(
                Icons.palette,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(AppLocalizations.getSettingsText('theme_title', appLanguage)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getThemeModeName(settings.themeMode, appLanguage)),
                  Text(
                    AppLocalizations.getSettingsText('theme_subtitle', appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    _getThemeModeIcon(mode),
                    color: settings.themeMode == mode
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  title: Text(_getThemeModeName(mode, appLanguage)),
                  subtitle: Text(
                    AppLocalizations.getSettingsText(descKey, appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          const Divider(),
          // About section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              AppLocalizations.getSettingsText('about_header', appLanguage),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.getSettingsText('version_title', appLanguage)),
            subtitle: ref.watch(packageInfoProvider).when(
                  data: (info) => Text('${info.version} (${info.buildNumber})'),
                  loading: () => const Text('…'),
                  error: (_, __) => const Text('—'),
                ),
          ),
          ListTile(
            leading: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.getSettingsText('support_title', appLanguage)),
            subtitle: Text(AppLocalizations.getSettingsText('support_subtitle', appLanguage)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openSupportLink(context),
            onLongPress: () => _showSupportInfo(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.getSettingsText('privacy_title', appLanguage)),
            subtitle: Text(AppLocalizations.getSettingsText('privacy_subtitle', appLanguage)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openPrivacyLink(context),
          ),
          ListTile(
            leading: Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.getSettingsText('terms_title', appLanguage)),
            subtitle: Text(AppLocalizations.getSettingsText('terms_subtitle', appLanguage)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openTermsLink(context),
          ),
          AboutDataSourcesTile(appLanguage: appLanguage),
        ],
      ),
    );
  }

  Widget _buildReciterTile(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reciterProvider);
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(
          Icons.headphones,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(AppLocalizations.getRecitationText('reciter', appLanguage)),
        subtitle: Text(
          selected.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  String _getLanguageName(String lang) {
    return switch (lang) {
      'id' => 'Indonesian',
      'en' => 'English',
      'zh' => 'Chinese',
      'ja' => 'Japanese',
      _ => lang,
    };
  }

  IconData _getLanguageIcon(String lang) {
    // Use translate icon for all languages
    return Icons.translate;
  }

  String _getThemeModeName(ThemeMode mode, String language) {
    return switch (mode) {
      ThemeMode.system => AppLocalizations.getSettingsText('theme_system', language),
      ThemeMode.light => AppLocalizations.getSettingsText('theme_light', language),
      ThemeMode.dark => AppLocalizations.getSettingsText('theme_dark', language),
    };
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.brightness_auto,
    };
  }


  Future<void> _openSupportLink(BuildContext context) async {
    final uri = Uri.parse('https://buymeacoffee.com/hendrawan');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  void _showSupportInfo(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.read(settingsProvider).appLanguage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.getSettingsText('support_dialog_title', appLanguage)),
        content: Text(
          AppLocalizations.getSettingsText('support_dialog_content', appLanguage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyLink(BuildContext context) async {
    final uri = Uri.parse('https://www.tursinalabs.com/privacy');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _openTermsLink(BuildContext context) async {
    final uri = Uri.parse('https://www.tursinalabs.com/terms');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }
}

