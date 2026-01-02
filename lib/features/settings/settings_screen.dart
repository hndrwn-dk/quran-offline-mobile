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
          SwitchListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(AppLocalizations.getSettingsText('show_tajweed_title', appLanguage)),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _showTajweedGuide(context, ref),
                  tooltip: 'Tajweed guide',
                ),
              ],
            ),
            subtitle: Text(
              AppLocalizations.getSettingsText('show_tajweed_subtitle', appLanguage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: settings.showTajweed,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTajweed(value);
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

  void _showTajweedGuide(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.read(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.getSettingsText('tajweed_guide_title', appLanguage)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.getSettingsText('tajweed_guide_intro', appLanguage),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_ikhfa', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_ikhfa_desc', appLanguage),
                isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00897B),
              ),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_idgham', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_idgham_desc', appLanguage),
                isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
              ),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_iqlab', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_iqlab_desc', appLanguage),
                isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2),
              ),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_ghunnah', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_ghunnah_desc', appLanguage),
                isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
              ),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_qalqalah', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_qalqalah_desc', appLanguage),
                isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
              ),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_laam_shamsiyah', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_laam_shamsiyah_desc', appLanguage),
                isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17),
              ),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_madd', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_madd_desc', appLanguage),
                isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
              ),
              _buildTajweedRuleItem(
                context,
                AppLocalizations.getSettingsText('tajweed_rule_ham_wasl', appLanguage),
                AppLocalizations.getSettingsText('tajweed_rule_ham_wasl_desc', appLanguage),
                colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.getSettingsText('tajweed_guide_closing', appLanguage),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.getSettingsText('tajweed_guide_got_it', appLanguage)),
          ),
        ],
      ),
    );
  }

  Widget _buildTajweedRuleItem(
    BuildContext context,
    String name,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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

