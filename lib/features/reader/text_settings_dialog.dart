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

  Future<void> _applySettings() async {
    final settings = ref.read(settingsProvider);
    if (_currentArabicSize != settings.arabicFontSize) {
      await ref.read(settingsProvider.notifier).updateArabicFontSize(_currentArabicSize);
    }
    if (_currentTranslationSize != settings.translationFontSize) {
      await ref.read(settingsProvider.notifier).updateTranslationFontSize(_currentTranslationSize);
    }
    if (_showTransliteration != settings.showTransliteration) {
      await ref.read(settingsProvider.notifier).updateShowTransliteration(_showTransliteration);
    }
    if (_showTranslation != settings.showTranslation) {
      await ref.read(settingsProvider.notifier).updateShowTranslation(_showTranslation);
    }
    if (_showTafsir != settings.showTafsir) {
      await ref.read(settingsProvider.notifier).updateShowTafsir(_showTafsir);
    }
    if (_showTajweed != settings.showTajweed) {
      await ref.read(settingsProvider.notifier).updateShowTajweed(_showTajweed);
    }
    if (_currentLanguage != settings.language) {
      await ref.read(settingsProvider.notifier).updateLocale(_currentLanguage);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  _TextSettingsLayout _layoutFor(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    if (height < 640) {
      return const _TextSettingsLayout(
        sheetHeightFactor: 0.94,
        horizontalPadding: 20,
        sectionGap: 12,
        cardRadius: 14,
        compactToggles: true,
      );
    }
    if (height < 800) {
      return const _TextSettingsLayout(
        sheetHeightFactor: 0.90,
        horizontalPadding: 24,
        sectionGap: 16,
        cardRadius: 16,
        compactToggles: true,
      );
    }
    return const _TextSettingsLayout(
      sheetHeightFactor: 0.86,
      horizontalPadding: 24,
      sectionGap: 20,
      cardRadius: 16,
      compactToggles: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final layout = _layoutFor(context);
    final viewHeight = MediaQuery.sizeOf(context).height;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = (viewHeight * layout.sheetHeightFactor)
        .clamp(360.0, viewHeight - MediaQuery.paddingOf(context).top - 16);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPadding,
                12,
                layout.horizontalPadding,
                layout.sectionGap,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.getSettingsText('text_settings_title', appLanguage),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsCard(
                      colorScheme: colorScheme,
                      radius: layout.cardRadius,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FontSizeSlider(
                            label: AppLocalizations.getSettingsText(
                              'text_settings_arabic_size',
                              appLanguage,
                            ),
                            value: _currentArabicSize,
                            min: 16,
                            max: 48,
                            divisions: 32,
                            sizeLabel: AppLocalizations.getSettingsText(
                              'text_settings_size_label',
                              appLanguage,
                            ),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onChanged: (value) => setState(() => _currentArabicSize = value),
                          ),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                          ),
                          _FontSizeSlider(
                            label: AppLocalizations.getSettingsText(
                              'text_settings_translation_size',
                              appLanguage,
                            ),
                            value: _currentTranslationSize,
                            min: 12,
                            max: 32,
                            divisions: 20,
                            sizeLabel: AppLocalizations.getSettingsText(
                              'text_settings_size_label',
                              appLanguage,
                            ),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onChanged: (value) =>
                                setState(() => _currentTranslationSize = value),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: layout.sectionGap),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      radius: layout.cardRadius,
                      padding: EdgeInsets.zero,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          childrenPadding: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(),
                          collapsedShape: const RoundedRectangleBorder(),
                          title: Text(
                            AppLocalizations.getSettingsText('language_title', appLanguage),
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            _getLanguageName(_currentLanguage, appLanguage),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          children: ['id', 'en', 'zh', 'ja'].map((lang) {
                            return RadioListTile<String>(
                              title: Text(_getLanguageName(lang, appLanguage)),
                              value: lang,
                              groupValue: _currentLanguage,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _currentLanguage = value);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: layout.sectionGap),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      radius: layout.cardRadius,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _CompactSwitchTile(
                            title: AppLocalizations.getSettingsText(
                              'show_transliteration_title',
                              appLanguage,
                            ),
                            value: _showTransliteration,
                            compact: layout.compactToggles,
                            onChanged: (value) =>
                                setState(() => _showTransliteration = value),
                          ),
                          _SettingsDivider(colorScheme: colorScheme),
                          _CompactSwitchTile(
                            title: AppLocalizations.getSettingsText(
                              'show_translation_title',
                              appLanguage,
                            ),
                            value: _showTranslation,
                            compact: layout.compactToggles,
                            onChanged: (value) =>
                                setState(() => _showTranslation = value),
                          ),
                          _SettingsDivider(colorScheme: colorScheme),
                          _CompactSwitchTile(
                            title: AppLocalizations.getSettingsText(
                              'show_tafsir_title',
                              appLanguage,
                            ),
                            value: _showTafsir,
                            compact: layout.compactToggles,
                            onChanged: (value) => setState(() => _showTafsir = value),
                          ),
                          _SettingsDivider(colorScheme: colorScheme),
                          _CompactSwitchTile(
                            title: AppLocalizations.getSettingsText(
                              'show_tajweed_title',
                              appLanguage,
                            ),
                            value: _showTajweed,
                            compact: layout.compactToggles,
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              visualDensity: VisualDensity.compact,
                              color: colorScheme.primary,
                              onPressed: () => _showTajweedGuide(context, colorScheme),
                              tooltip: AppLocalizations.getSettingsText(
                                'tajweed_guide_title',
                                appLanguage,
                              ),
                            ),
                            onChanged: (value) => setState(() => _showTajweed = value),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: layout.sectionGap),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPadding,
                12,
                layout.horizontalPadding,
                12 + safeBottom,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: FilledButton(
                onPressed: _applySettings,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(AppLocalizations.getSettingsText('apply', appLanguage)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextSettingsLayout {
  const _TextSettingsLayout({
    required this.sheetHeightFactor,
    required this.horizontalPadding,
    required this.sectionGap,
    required this.cardRadius,
    required this.compactToggles,
  });

  final double sheetHeightFactor;
  final double horizontalPadding;
  final double sectionGap;
  final double cardRadius;
  final bool compactToggles;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.colorScheme,
    required this.radius,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final ColorScheme colorScheme;
  final double radius;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _FontSizeSlider extends StatelessWidget {
  const _FontSizeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.sizeLabel,
    required this.colorScheme,
    required this.textTheme,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String sizeLabel;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$sizeLabel: ${value.toInt()}',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                min.toInt().toString(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: value.toInt().toString(),
                  onChanged: onChanged,
                ),
              ),
              Text(
                max.toInt().toString(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactSwitchTile extends StatelessWidget {
  const _CompactSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.trailing,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
      value: value,
      dense: compact,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 0 : 4,
      ),
      onChanged: onChanged,
    );
  }
}
