import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Preferences & display',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_getLanguageName(settings.language)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, ref),
          ),
          SwitchListTile(
            title: const Text('Show Transliteration'),
            value: settings.showTransliteration,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTransliteration(value);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeName(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref),
          ),
          const Divider(),
          // About / Support section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            title: const Text('Support the developer'),
            subtitle: const Text('Optional donation via Buy Me a Coffee'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openSupportLink(context),
            onLongPress: () => _showSupportInfo(context),
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

  String _getThemeModeName(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final languages = ['id', 'en', 'zh', 'ja'];
    final currentLang = ref.read(settingsProvider).language;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(_getLanguageName(lang)),
              value: lang,
              groupValue: currentLang,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(settingsProvider).themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeName(mode)),
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

  void _showSupportInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support the developer'),
        content: const Text(
          'This is an optional external donation and does not unlock features.',
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
}

