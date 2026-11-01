import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Re-enable when QPC V2 glyph Mushaf font-size slider is wired again.
const kMushafGlyphTextSettingsUiEnabled = false;

/// Whether the Mushaf AppBar "Tt" entry should show.
///
/// Legacy Mushaf always shows it. Glyph Mushaf shows it once the font slider is
/// re-enabled or when the window can show a two-page spread (so the spread
/// toggle stays reachable).
Future<bool> isMushafTextSettingsAppBarVisible(BuildContext context) async {
  // Read MediaQuery before the await so the context is not reused across a gap.
  final spreadFits = mushafSpreadAvailable(context);
  if (!await QpcV2MushafLayout.isAvailable()) return true;
  if (kMushafGlyphTextSettingsUiEnabled) return true;
  return spreadFits;
}

/// Approximate reader chrome (status bar + AppBar + system bottom inset).
const double kMushafReaderChromeHeight = 140.0;

/// Whether this window has room for a two-page spread.
bool mushafSpreadAvailable(BuildContext context) {
  final media = MediaQuery.of(context);
  final metrics = resolveMushafSpread(
    available: Size(
      media.size.width,
      media.size.height - kMushafReaderChromeHeight,
    ),
    displayFeatures: media.displayFeatures,
    spreadEnabled: true,
  );
  return metrics.showSpread;
}


class MushafTextSettingsDialog extends ConsumerStatefulWidget {
  const MushafTextSettingsDialog({super.key});

  @override
  ConsumerState<MushafTextSettingsDialog> createState() =>
      _MushafTextSettingsDialogState();
}

class _MushafTextSettingsDialogState
    extends ConsumerState<MushafTextSettingsDialog> {
  double _currentSize = 28.0;
  bool _twoPageSpread = true;
  late final Future<bool> _glyphMushafActive;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currentSize = settings.mushafFontSize;
    _twoPageSpread = settings.mushafTwoPageSpread;
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
        final showFontSize =
            !isGlyphMushaf || kMushafGlyphTextSettingsUiEnabled;
        final showSpreadToggle = mushafSpreadAvailable(context);

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
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
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                if (showFontSize) ...[
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
              ],
              if (showSpreadToggle) ...[
                const SizedBox(height: 8),
                Material(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      AppLocalizations.getSettingsText(
                        'mushaf_two_page_title',
                        appLanguage,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                    ),
                    subtitle: Text(
                      AppLocalizations.getSettingsText(
                        'mushaf_two_page_subtitle',
                        appLanguage,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    value: _twoPageSpread,
                    onChanged: (value) {
                      setState(() => _twoPageSpread = value);
                    },
                  ),
                ),
              ],
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
                    if (_twoPageSpread != settings.mushafTwoPageSpread) {
                      await ref
                          .read(settingsProvider.notifier)
                          .updateMushafTwoPageSpread(_twoPageSpread);
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
