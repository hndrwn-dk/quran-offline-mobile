import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';

class MushafTextSettingsDialog extends ConsumerStatefulWidget {
  const MushafTextSettingsDialog({super.key});

  @override
  ConsumerState<MushafTextSettingsDialog> createState() => _MushafTextSettingsDialogState();
}

class _MushafTextSettingsDialogState extends ConsumerState<MushafTextSettingsDialog> {
  double _currentSize = 28.0;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currentSize = settings.mushafFontSize;
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
          // Arabic Size Slider
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
                '28',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentSize,
                  min: 28,
                  max: 40,
                  divisions: 12, // 28-40 with step 1
                  label: _currentSize.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      _currentSize = value;
                    });
                  },
                ),
              ),
              Text(
                '40',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: Text(
              'Size: ${_currentSize.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                style: TextStyle(
                  fontSize: _currentSize,
                  fontFamily: 'UthmanicHafsV22',
                  fontFamilyFallback: const ['UthmanicHafs'],
                  height: 1.6,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (_currentSize != settings.mushafFontSize) {
                  // Invalidate cache for old font size
                  await MushafLayoutCache.invalidateCacheForFontSize(settings.mushafFontSize);
                  // Update setting
                  await ref.read(settingsProvider.notifier).updateMushafFontSize(_currentSize);
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

