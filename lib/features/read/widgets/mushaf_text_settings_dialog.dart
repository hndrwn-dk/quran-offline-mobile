import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_turn_picker.dart';

/// Re-enable when QPC V2 glyph Mushaf font-size slider is wired again.
const kMushafGlyphTextSettingsUiEnabled = false;

/// Whether the Mushaf AppBar "Tampilan Mushaf" entry should show.
///
/// Legacy Mushaf always shows it. Glyph Mushaf shows it once the font slider is
/// re-enabled or when the window can show a two-page spread (so the spread
/// toggle stays reachable). Phones reach the page-turn choice in Settings.
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
    displayFeatures: mushafCreaseFeatures(media.size, media.displayFeatures),
    spreadEnabled: true,
  );
  return metrics.showSpread;
}

/// "Tampilan Mushaf" sheet: two-page spread (when it fits) and the page turn.
///
/// Every control applies immediately; the sheet closes by swiping down or
/// tapping outside. The legacy (non-glyph) Mushaf also keeps its font size.
class MushafTextSettingsDialog extends ConsumerStatefulWidget {
  const MushafTextSettingsDialog({super.key});

  @override
  ConsumerState<MushafTextSettingsDialog> createState() =>
      _MushafTextSettingsDialogState();
}

class _MushafTextSettingsDialogState
    extends ConsumerState<MushafTextSettingsDialog> {
  late final Future<bool> _glyphMushafActive =
      QpcV2MushafLayout.isAvailable();

  /// Slider position while dragging (saved when the drag ends).
  double? _dragSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final appLanguage = settings.appLanguage;
    String text(String key) =>
        AppLocalizations.getSettingsText(key, appLanguage);

    return FutureBuilder<bool>(
      future: _glyphMushafActive,
      builder: (context, glyphSnapshot) {
        final isGlyphMushaf = glyphSnapshot.data ?? true;
        final showFontSize =
            !isGlyphMushaf || kMushafGlyphTextSettingsUiEnabled;
        final sliderMin = isGlyphMushaf ? kMushafGlyphMinFontSize : 20.0;
        final sliderMax = isGlyphMushaf ? kMushafGlyphReferenceFontSize : 44.0;
        final size =
            (_dragSize ?? settings.mushafFontSize).clamp(sliderMin, sliderMax);
        final showSpreadToggle = mushafSpreadAvailable(context);

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    text('mushaf_display_title'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (showFontSize) ...[
                    Text(
                      text('text_settings_arabic_size'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Slider(
                      value: size,
                      min: sliderMin,
                      max: sliderMax,
                      divisions: (sliderMax - sliderMin).round(),
                      label: size.toInt().toString(),
                      onChanged: (value) => setState(() => _dragSize = value),
                      onChangeEnd: (value) {
                        setState(() => _dragSize = null);
                        notifier.updateMushafFontSize(value);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (showSpreadToggle) ...[
                    Material(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          text('mushaf_two_page_title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          text('mushaf_two_page_subtitle'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: settings.mushafTwoPageSpread,
                        onChanged: notifier.updateMushafTwoPageSpread,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    text('page_turn_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text('page_turn_subtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MushafPageTurnPicker(
                    value: settings.pageTurnFor(
                      framed: MediaQuery.sizeOf(context).width >=
                          kMushafMinSpreadWindowWidth,
                    ),
                    language: appLanguage,
                    onChanged: notifier.updateMushafPageTurn,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
