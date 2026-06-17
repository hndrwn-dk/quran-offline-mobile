import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

class MushafTextSettingsDialog extends ConsumerStatefulWidget {
  const MushafTextSettingsDialog({super.key});

  @override
  ConsumerState<MushafTextSettingsDialog> createState() =>
      _MushafTextSettingsDialogState();
}

class _MushafTextSettingsDialogState
    extends ConsumerState<MushafTextSettingsDialog> {
  double _currentSize = 28.0;
  late final Future<bool> _glyphMushafActive;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currentSize = settings.mushafFontSize;
    _glyphMushafActive = QpcV2MushafLayout.isAvailable();
    _glyphMushafActive.then((isGlyph) {
      if (!mounted) return;
      final max = isGlyph ? kMushafGlyphReferenceFontSize : 44.0;
      final min = isGlyph ? kMushafGlyphMinFontSize : 20.0;
      final clamped = _currentSize.clamp(min, max);
      if (clamped != _currentSize) {
        setState(() => _currentSize = clamped);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;

    return FutureBuilder<bool>(
      future: _glyphMushafActive,
      builder: (context, glyphSnapshot) {
        final isGlyphMushaf = glyphSnapshot.data ?? false;
        final sliderMin = isGlyphMushaf ? kMushafGlyphMinFontSize : 20.0;
        final sliderMax = isGlyphMushaf ? kMushafGlyphReferenceFontSize : 44.0;
        final sliderDivisions = (sliderMax - sliderMin).round();

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
              Text(
                AppLocalizations.getSettingsText(
                  'text_settings_title',
                  appLanguage,
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              if (isGlyphMushaf) ...[
                const SizedBox(height: 10),
                Text(
                  _glyphModeNote(appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                AppLocalizations.getSettingsText(
                  'text_settings_arabic_size',
                  appLanguage,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    sliderMin.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentSize.clamp(sliderMin, sliderMax),
                      min: sliderMin,
                      max: sliderMax,
                      divisions: sliderDivisions,
                      label: _currentSize.toInt().toString(),
                      onChanged: (value) {
                        setState(() => _currentSize = value);
                      },
                    ),
                  ),
                  Text(
                    sliderMax.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Text(
                  '${AppLocalizations.getSettingsText('text_settings_size_label', appLanguage)}: ${_currentSize.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (isGlyphMushaf)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Text(
                    _glyphSizeNote(appLanguage, _currentSize),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ),
              if (!isGlyphMushaf)
                SwitchListTile(
                  value: settings.showTajweed,
                  onChanged: (value) async {
                    await ref
                        .read(settingsProvider.notifier)
                        .updateShowTajweed(value);
                  },
                  title: Text(
                    AppLocalizations.getSettingsText(
                      'show_tajweed_title',
                      appLanguage,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                  subtitle: Text(
                    AppLocalizations.getSettingsText(
                      'text_settings_tajweed_subtitle',
                      appLanguage,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_currentSize != settings.mushafFontSize) {
                      await ref
                          .read(settingsProvider.notifier)
                          .updateMushafFontSize(_currentSize);
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.getSettingsText('apply', appLanguage),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _glyphModeNote(String lang) {
    switch (lang) {
      case 'id':
        return 'Mode Mushaf glyph (QPC V2): ukuran mengikuti lebar halaman. '
            'Monokrom — tanpa warna tajweed.';
      case 'ja':
        return 'グリフ Mushaf（QPC V2）：ページ幅に合わせます。'
            '単色（タジュウィード色なし）。';
      case 'zh':
        return '字形 Mushaf（QPC V2）：大小随页面宽度。'
            '单色，无塔吉威德着色。';
      default:
        return 'Glyph Mushaf (QPC V2): size scales to page width. '
            'Monochrome — no tajweed colors.';
    }
  }

  String _glyphSizeNote(String lang, double size) {
    final ref = kMushafGlyphReferenceFontSize.toInt();
    final pct = ((size / kMushafGlyphReferenceFontSize) * 100).round();
    switch (lang) {
      case 'id':
        return 'Nilai $ref = penuh lebar halaman (~$pct%). '
            'Rentang ${kMushafGlyphMinFontSize.toInt()}–$ref menyesuaikan skala.';
      case 'ja':
        return '$ref = ページ幅いっぱい（約$pct%）。'
            '${kMushafGlyphMinFontSize.toInt()}–$ref で拡大率を調整します。';
      case 'zh':
        return '$ref = 满页宽（约 $pct%）。'
            '${kMushafGlyphMinFontSize.toInt()}–$ref 调整缩放。';
      default:
        return '$ref = full page width (~$pct%). '
            'Range ${kMushafGlyphMinFontSize.toInt()}–$ref scales size.';
    }
  }
}
