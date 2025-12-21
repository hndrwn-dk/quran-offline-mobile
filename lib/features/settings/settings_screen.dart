import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 54,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            ),
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
              title: Text(AppLocalizations.getSettingsText('translation_language_title', appLanguage)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLanguageName(settings.language),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    AppLocalizations.getSettingsText('translation_language_subtitle', appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              childrenPadding: EdgeInsets.zero,
              children: ['id', 'en', 'zh', 'ja'].map((lang) {
                return RadioListTile<String>(
                  title: Text(_getLanguageName(lang)),
                  value: lang,
                  groupValue: settings.language,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateLanguage(value);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            title: Text(AppLocalizations.getSettingsText('show_transliteration_title', appLanguage)),
            subtitle: Text(
              AppLocalizations.getSettingsText('show_transliteration_subtitle', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: settings.showTransliteration,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTransliteration(value);
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
              title: Text(AppLocalizations.getSettingsText('app_language_title', appLanguage)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLanguageName(settings.appLanguage),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    AppLocalizations.getSettingsText('app_language_subtitle', appLanguage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              childrenPadding: EdgeInsets.zero,
              children: ['id', 'en', 'zh', 'ja'].map((lang) {
                return RadioListTile<String>(
                  title: Text(_getLanguageName(lang)),
                  value: lang,
                  groupValue: settings.appLanguage,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateAppLanguage(value);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          ListTile(
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref),
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
            title: Text(AppLocalizations.getSettingsText('support_title', appLanguage)),
            subtitle: Text(AppLocalizations.getSettingsText('support_subtitle', appLanguage)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openSupportLink(context),
            onLongPress: () => _showSupportInfo(context, ref),
          ),
          ListTile(
            title: Text(AppLocalizations.getSettingsText('privacy_title', appLanguage)),
            subtitle: Text(AppLocalizations.getSettingsText('privacy_subtitle', appLanguage)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openPrivacyLink(context),
          ),
          ListTile(
            title: Text(AppLocalizations.getSettingsText('terms_title', appLanguage)),
            subtitle: Text(AppLocalizations.getSettingsText('terms_subtitle', appLanguage)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openTermsLink(context),
          ),
        ],
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

  String _getThemeModeName(ThemeMode mode, String language) {
    return switch (mode) {
      ThemeMode.system => AppLocalizations.getSettingsText('theme_system', language),
      ThemeMode.light => AppLocalizations.getSettingsText('theme_light', language),
      ThemeMode.dark => AppLocalizations.getSettingsText('theme_dark', language),
    };
  }


  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(settingsProvider).themeMode;
    final appLanguage = ref.read(settingsProvider).appLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.getSettingsText('select_theme_dialog', appLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeName(mode, appLanguage)),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
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
    final uri = Uri.parse('https://www.tursinalab.com/privacy');
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
    final uri = Uri.parse('https://www.tursinalab.com/terms');
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

