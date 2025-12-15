import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';

class TextSettingsDialog extends ConsumerStatefulWidget {
  const TextSettingsDialog({super.key});

  @override
  ConsumerState<TextSettingsDialog> createState() => _TextSettingsDialogState();
}

class _TextSettingsDialogState extends ConsumerState<TextSettingsDialog> {
  double _currentArabicSize = 24.0;
  double _currentTranslationSize = 16.0;
  bool _showTransliteration = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currentArabicSize = settings.arabicFontSize;
    _currentTranslationSize = settings.translationFontSize;
    _showTransliteration = settings.showTransliteration;
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
          // Transliteration Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                  child: Text(
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
                  'In the name of Allah, the Most Gracious, the Most Merciful',
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
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

