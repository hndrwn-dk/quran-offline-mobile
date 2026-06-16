import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/widgets/tajweed_color_guide.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

class TextSettingsDialog extends ConsumerStatefulWidget {
  const TextSettingsDialog({super.key});

  @override
  ConsumerState<TextSettingsDialog> createState() => _TextSettingsDialogState();
}

class _TextSettingsDialogState extends ConsumerState<TextSettingsDialog> {
  double _currentArabicSize = 24.0;
  double _currentTranslationSize = 16.0;
  bool _showTransliteration = false;
  bool _showTranslation = true;
  bool _showTafsir = false;
  bool _showTajweed = false;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currentArabicSize = settings.arabicFontSize;
    _currentTranslationSize = settings.translationFontSize;
    _showTransliteration = settings.showTransliteration;
    _showTranslation = settings.showTranslation;
    _showTafsir = settings.showTafsir;
    _showTajweed = settings.showTajweed;
    _currentLanguage = settings.language;
  }

  String _getLanguageName(String lang, String appLanguage) {
    return switch (lang) {
      'id' => AppLocalizations.getSettingsText('language_name_indonesian', appLanguage),
      'en' => AppLocalizations.getSettingsText('language_name_english', appLanguage),
      'zh' => AppLocalizations.getSettingsText('language_name_chinese', appLanguage),
      'ja' => AppLocalizations.getSettingsText('language_name_japanese', appLanguage),
      _ => lang,
    };
  }

  void _showTajweedGuide(BuildContext context, ColorScheme colorScheme) {
    final settings = ref.read(settingsProvider);
    final appLanguage = settings.appLanguage;

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
              TajweedColorGuideContent(appLanguage: appLanguage),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            AppLocalizations.getSettingsText('text_settings_title', appLanguage),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          // Arabic Font Size Slider
          Text(
            AppLocalizations.getSettingsText('text_settings_arabic_size', appLanguage),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '16',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentArabicSize,
                  min: 16,
                  max: 48,
                  divisions: 32, // 16-48 with step 1
                  label: _currentArabicSize.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      _currentArabicSize = value;
                    });
                  },
                ),
              ),
              Text(
                '48',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              '${AppLocalizations.getSettingsText('text_settings_size_label', appLanguage)}: ${_currentArabicSize.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Translation Font Size Slider
          Text(
            AppLocalizations.getSettingsText('text_settings_translation_size', appLanguage),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '12',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentTranslationSize,
                  min: 12,
                  max: 32,
                  divisions: 20, // 12-32 with step 1
                  label: _currentTranslationSize.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      _currentTranslationSize = value;
                    });
                  },
                ),
              ),
              Text(
                '32',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              '${AppLocalizations.getSettingsText('text_settings_size_label', appLanguage)}: ${_currentTranslationSize.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Translation Language
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  AppLocalizations.getSettingsText('language_title', appLanguage),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  _getLanguageName(_currentLanguage, appLanguage),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                childrenPadding: EdgeInsets.zero,
                children: ['id', 'en', 'zh', 'ja'].map((lang) {
                  return RadioListTile<String>(
                    title: Text(_getLanguageName(lang, appLanguage)),
                    value: lang,
                    groupValue: _currentLanguage,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _currentLanguage = value;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          // Transliteration Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                AppLocalizations.getSettingsText('show_transliteration_title', appLanguage),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              value: _showTransliteration,
              onChanged: (value) {
                setState(() {
                  _showTransliteration = value;
                });
              },
            ),
          ),
          // Translation Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                AppLocalizations.getSettingsText('show_translation_title', appLanguage),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              value: _showTranslation,
              onChanged: (value) {
                setState(() {
                  _showTranslation = value;
                });
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                AppLocalizations.getSettingsText('show_tafsir_title', appLanguage),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              value: _showTafsir,
              onChanged: (value) {
                setState(() {
                  _showTafsir = value;
                });
              },
            ),
          ),
          // Tajweed Toggle (no subtitle to keep option compact)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Row(
                children: [
                  Text(
                    AppLocalizations.getSettingsText('show_tajweed_title', appLanguage),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    color: colorScheme.primary,
                    onPressed: () => _showTajweedGuide(context, colorScheme),
                    tooltip: AppLocalizations.getSettingsText('tajweed_guide_title', appLanguage),
                  ),
                ],
              ),
              value: _showTajweed,
              onChanged: (value) {
                setState(() {
                  _showTajweed = value;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                // Update Arabic font size
                if (_currentArabicSize != settings.arabicFontSize) {
                  await ref.read(settingsProvider.notifier).updateArabicFontSize(_currentArabicSize);
                }
                // Update Translation font size
                if (_currentTranslationSize != settings.translationFontSize) {
                  await ref.read(settingsProvider.notifier).updateTranslationFontSize(_currentTranslationSize);
                }
                // Update Transliteration
                if (_showTransliteration != settings.showTransliteration) {
                  await ref.read(settingsProvider.notifier).updateShowTransliteration(_showTransliteration);
                }
                // Update Translation
                if (_showTranslation != settings.showTranslation) {
                  await ref.read(settingsProvider.notifier).updateShowTranslation(_showTranslation);
                }
                if (_showTafsir != settings.showTafsir) {
                  await ref.read(settingsProvider.notifier).updateShowTafsir(_showTafsir);
                }
                // Update Tajweed
                if (_showTajweed != settings.showTajweed) {
                  await ref.read(settingsProvider.notifier).updateShowTajweed(_showTajweed);
                }
                // Update Language
                if (_currentLanguage != settings.language) {
                  await ref.read(settingsProvider.notifier).updateLocale(_currentLanguage);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.getSettingsText('apply', appLanguage)),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

