import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';
import 'package:quran_offline/features/reader/widgets/highlight_color_picker.dart';

class HighlightsScreen extends ConsumerStatefulWidget {
  const HighlightsScreen({super.key});

  @override
  ConsumerState<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends ConsumerState<HighlightsScreen> {
  int? _filterColor;

  @override
  Widget build(BuildContext context) {
    ref.watch(highlightRefreshProvider);
    final highlightsAsync = ref.watch(highlightsProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Color filter chips with info icon (no search button - use global search in AppBar)
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildColorChip(
                          context,
                          null,
                          'All',
                          colorScheme,
                          _filterColor == null,
                          () => setState(() => _filterColor = null),
                        ),
                        const SizedBox(width: 8),
                        ...highlightColors.map((colorValue) {
                          final color = Color(colorValue);
                          final isSelected = _filterColor == colorValue;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildColorChip(
                              context,
                              color,
                              null,
                              colorScheme,
                              isSelected,
                              () => setState(() => _filterColor = isSelected ? null : colorValue),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: colorScheme.onSurfaceVariant),
                  tooltip: 'Highlight color guide',
                  onPressed: () => _showHighlightGuide(context, settings),
                ),
              ],
            ),
          ),
        // Highlights list
        Expanded(
          child: highlightsAsync.when(
            data: (highlights) {
              return surahsAsync.when(
                data: (surahs) {
                  // Filter by color only (no search filtering in tab view)
                  var filtered = highlights.where((highlight) {
                    if (_filterColor != null && highlight.color != _filterColor) {
                      return false;
                    }
                    return true;
                  }).toList();
                  
                  // Sort by surah, then ayah
                  filtered.sort((a, b) {
                    if (a.surahId != b.surahId) {
                      return a.surahId.compareTo(b.surahId);
                    }
                    return a.ayahNo.compareTo(b.ayahNo);
                  });

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        highlights.isEmpty
                            ? AppLocalizations.getSubtitleText('highlights_empty', settings.appLanguage)
                            : AppLocalizations.getSubtitleText('highlights_no_results', settings.appLanguage),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final highlight = filtered[index];
                      final surahInfo = surahs.firstWhere(
                        (s) => s.id == highlight.surahId,
                        orElse: () => SurahInfo(
                          id: highlight.surahId,
                          arabicName: '',
                          englishName: 'Surah ${highlight.surahId}',
                          englishMeaning: '',
                        ),
                      );
                      final highlightColor = Color(highlight.color);

                      return FutureBuilder<Verse?>(
                        future: ref.read(databaseProvider).getVerse(highlight.surahId, highlight.ayahNo),
                        builder: (context, verseSnapshot) {
                          final verse = verseSnapshot.data;
                          final arabicText = verse?.arabic ?? '';
                          final translation = _getTranslation(verse, settings.language);
                          
                          return InkWell(
                            onTap: () {
                              ref.read(readerSourceProvider.notifier).state = SurahSource(
                                highlight.surahId,
                                targetAyahNo: highlight.ayahNo,
                              );
                              ref.read(targetAyahProvider.notifier).state = highlight.ayahNo;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReaderScreen(),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.only(
                                bottom: index == filtered.length - 1 ? 0 : 12,
                              ),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: highlightColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Color indicator
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: highlightColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: highlightColor,
                                          width: 2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${highlight.surahId}',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: highlightColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  surahInfo.englishName,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                ),
                                              ),
                                              Text(
                                                'Ayah ${highlight.ayahNo}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          if (arabicText.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: Text(
                                                arabicText,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontFamily: 'UthmanicHafsV22',
                                                      fontFamilyFallback: const ['UthmanicHafs'],
                                                      color: colorScheme.onSurface,
                                                      height: 1.6,
                                                    ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                          if (translation.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              translation,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    height: 1.4,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: colorScheme.onSurfaceVariant),
                                      tooltip: 'Change color',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => HighlightColorPicker(
                                            surahId: highlight.surahId,
                                            ayahNo: highlight.ayahNo,
                                            currentColor: highlight.color,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorChip(
    BuildContext context,
    Color? color,
    String? label,
    ColorScheme colorScheme,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData? icon;
    if (color != null) {
      icon = getHighlightIcon(color.value);
    }
    
    // Adjust colors for dark mode
    Color? chipBackgroundColor;
    Color chipBorderColor;
    Color iconContainerColor;
    
    if (color != null) {
      if (isSelected) {
        // Selected: use muted color in dark mode, full color in light mode
        chipBackgroundColor = isDark 
            ? color.withOpacity(0.25) 
            : color.withOpacity(0.15);
        chipBorderColor = isDark 
            ? color.withOpacity(0.6) 
            : color;
      } else {
        // Unselected: very subtle in dark mode
        chipBackgroundColor = isDark 
            ? colorScheme.surfaceVariant 
            : color.withOpacity(0.1);
        chipBorderColor = isDark 
            ? colorScheme.outline.withOpacity(0.2)
            : colorScheme.outline.withOpacity(0.3);
      }
      iconContainerColor = color;
    } else {
      // "All" chip
      chipBackgroundColor = isSelected 
          ? colorScheme.primaryContainer 
          : colorScheme.surfaceVariant;
      chipBorderColor = isSelected 
          ? colorScheme.primary 
          : colorScheme.outline.withOpacity(0.3);
      iconContainerColor = colorScheme.primary;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chipBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconContainerColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark 
                        ? colorScheme.outline.withOpacity(0.2)
                        : colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 12,
                  color: _getContrastColor(iconContainerColor),
                ),
              ),
              if (label != null) const SizedBox(width: 6),
            ],
            if (label != null)
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? (color != null && isDark
                              ? color.withOpacity(0.9)
                              : color ?? colorScheme.onPrimaryContainer)
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate relative luminance
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _showHighlightGuide(BuildContext context, AppSettings settings) {
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.getSettingsText('highlight_guide_title', appLanguage)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.getSettingsText('highlight_guide_intro', appLanguage),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ...highlightColors.map((colorValue) {
                final color = Color(colorValue);
                final icon = getHighlightIcon(colorValue);
                return _buildHighlightRuleItem(
                  context,
                  _getHighlightColorName(colorValue, appLanguage),
                  _getHighlightColorDescription(colorValue, appLanguage),
                  color,
                  icon,
                );
              }),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.getSettingsText('highlight_guide_closing', appLanguage),
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
            child: Text(AppLocalizations.getSettingsText('highlight_guide_got_it', appLanguage)),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRuleItem(
    BuildContext context,
    String name,
    String description,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: _getContrastColor(color),
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

  String _getHighlightColorName(int colorValue, String language) {
    final color = Color(colorValue);
    return switch (colorValue) {
      _ when color == Colors.yellow || color.value == Colors.yellow.toARGB32() => AppLocalizations.getSettingsText('highlight_color_yellow', language),
      _ when color == Colors.orange || color.value == Colors.orange.toARGB32() => AppLocalizations.getSettingsText('highlight_color_orange', language),
      _ when color == Colors.pink || color.value == Colors.pink.toARGB32() => AppLocalizations.getSettingsText('highlight_color_pink', language),
      _ when color == Colors.red || color.value == Colors.red.toARGB32() => AppLocalizations.getSettingsText('highlight_color_red', language),
      _ when color == Colors.purple || color.value == Colors.purple.toARGB32() => AppLocalizations.getSettingsText('highlight_color_purple', language),
      _ when color == Colors.blue || color.value == Colors.blue.toARGB32() => AppLocalizations.getSettingsText('highlight_color_blue', language),
      _ when color == Colors.cyan || color.value == Colors.cyan.toARGB32() => AppLocalizations.getSettingsText('highlight_color_cyan', language),
      _ when color == Colors.green || color.value == Colors.green.toARGB32() => AppLocalizations.getSettingsText('highlight_color_green', language),
      _ when color == Colors.teal || color.value == Colors.teal.toARGB32() => AppLocalizations.getSettingsText('highlight_color_teal', language),
      _ => AppLocalizations.getSettingsText('highlight_color_other', language),
    };
  }

  String _getHighlightColorDescription(int colorValue, String language) {
    final color = Color(colorValue);
    return switch (colorValue) {
      _ when color == Colors.yellow || color.value == Colors.yellow.toARGB32() => AppLocalizations.getSettingsText('highlight_color_yellow_desc', language),
      _ when color == Colors.orange || color.value == Colors.orange.toARGB32() => AppLocalizations.getSettingsText('highlight_color_orange_desc', language),
      _ when color == Colors.pink || color.value == Colors.pink.toARGB32() => AppLocalizations.getSettingsText('highlight_color_pink_desc', language),
      _ when color == Colors.red || color.value == Colors.red.toARGB32() => AppLocalizations.getSettingsText('highlight_color_red_desc', language),
      _ when color == Colors.purple || color.value == Colors.purple.toARGB32() => AppLocalizations.getSettingsText('highlight_color_purple_desc', language),
      _ when color == Colors.blue || color.value == Colors.blue.toARGB32() => AppLocalizations.getSettingsText('highlight_color_blue_desc', language),
      _ when color == Colors.cyan || color.value == Colors.cyan.toARGB32() => AppLocalizations.getSettingsText('highlight_color_cyan_desc', language),
      _ when color == Colors.green || color.value == Colors.green.toARGB32() => AppLocalizations.getSettingsText('highlight_color_green_desc', language),
      _ when color == Colors.teal || color.value == Colors.teal.toARGB32() => AppLocalizations.getSettingsText('highlight_color_teal_desc', language),
      _ => AppLocalizations.getSettingsText('highlight_color_other_desc', language),
    };
  }

  String _getTranslation(Verse? verse, String language) {
    if (verse == null) return '';
    return switch (language) {
      'en' => verse.trEn ?? '',
      'id' => verse.trId ?? '',
      'zh' => verse.trZh ?? '',
      'ja' => verse.trJa ?? '',
      _ => verse.trId ?? verse.trEn ?? '',
    };
  }
}

