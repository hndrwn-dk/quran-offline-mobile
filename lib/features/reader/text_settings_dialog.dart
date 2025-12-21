import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

class TextSettingsDialog extends ConsumerStatefulWidget {
  const TextSettingsDialog({super.key});

  @override
  ConsumerState<TextSettingsDialog> createState() => _TextSettingsDialogState();
}

class _TextSettingsDialogState extends ConsumerState<TextSettingsDialog> {
  double _currentArabicSize = 24.0;
  double _currentTranslationSize = 16.0;
  bool _showTransliteration = false;
  bool _showTajweed = false;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currentArabicSize = settings.arabicFontSize;
    _currentTranslationSize = settings.translationFontSize;
    _showTransliteration = settings.showTransliteration;
    _showTajweed = settings.showTajweed;
    _currentLanguage = settings.language;
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

  void _showTajweedGuide(BuildContext context, ColorScheme colorScheme) {
    final settings = ref.read(settingsProvider);
    final appLanguage = settings.appLanguage;
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


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);

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
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            'Text Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          // Arabic Font Size Slider
          Text(
            'Arabic Size',
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
              'Size: ${_currentArabicSize.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Translation Font Size Slider
          Text(
            'Translation Size',
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
              'Size: ${_currentTranslationSize.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Translation Language
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  'Translation Language',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  _getLanguageName(_currentLanguage),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                childrenPadding: EdgeInsets.zero,
                children: ['id', 'en', 'zh', 'ja'].map((lang) {
                  return RadioListTile<String>(
                    title: Text(_getLanguageName(lang)),
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
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                'Show Transliteration',
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
          // Tajweed Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Row(
                children: [
                  Text(
                    'Show Tajweed',
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
                    tooltip: 'Tajweed guide',
                  ),
                ],
              ),
              subtitle: Text(
                'Color-coded tajweed rules for proper recitation',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: _showTajweed
                      ? TajweedText(
                          tajweedHtml: 'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ <tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed>رَّحْمَ<tajweed class=madda_normal>ـٰ</tajweed>نِ <tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed>رَّح<tajweed class=madda_permissible>ِي</tajweed>مِ',
                          fontSize: _currentArabicSize,
                          defaultColor: colorScheme.onSurface,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          height: 1.7,
                        )
                      : Text(
                          'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                          style: TextStyle(
                            fontSize: _currentArabicSize,
                            fontFamily: 'UthmanicHafsV22',
                            fontFamilyFallback: const ['UthmanicHafs'],
                            height: 1.7,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.right,
                        ),
                ),
                if (_showTransliteration) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Bismillahirrahmanirrahim',
                    style: TextStyle(
                      fontSize: _currentTranslationSize * 0.85,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  Bismillah.getTranslation(_currentLanguage),
                  style: TextStyle(
                    fontSize: _currentTranslationSize,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
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
                // Update Tajweed
                if (_showTajweed != settings.showTajweed) {
                  await ref.read(settingsProvider.notifier).updateShowTajweed(_showTajweed);
                }
                // Update Language
                if (_currentLanguage != settings.language) {
                  await ref.read(settingsProvider.notifier).updateLanguage(_currentLanguage);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Apply'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

