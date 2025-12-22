import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

class HighlightColorPicker extends ConsumerWidget {
  final int surahId;
  final int ayahNo;
  final int? currentColor;

  const HighlightColorPicker({
    super.key,
    required this.surahId,
    required this.ayahNo,
    this.currentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(AppLocalizations.getSettingsText('highlight_title', appLanguage)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: highlightColors.map((colorValue) {
              final color = Color(colorValue);
              final isSelected = currentColor == colorValue;
              final icon = getHighlightIcon(colorValue);
              final colorDescription = _getHighlightColorDescription(colorValue, appLanguage);
              return GestureDetector(
                onTap: () async {
                  await toggleHighlight(ref, surahId, ayahNo, colorValue);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            icon,
                            color: _getContrastColor(color),
                            size: 24,
                          ),
                          if (isSelected)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 48,
                      child: Text(
                        colorDescription,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 10,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (currentColor != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                await removeHighlight(ref, surahId, ayahNo);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              label: Text(AppLocalizations.getSettingsText('remove_highlight', appLanguage)),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.getSettingsText('cancel', appLanguage)),
        ),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate relative luminance
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  String _getHighlightColorDescription(int colorValue, String language) {
    final color = Color(colorValue);
    // Return short labels for color picker
    return switch (colorValue) {
      _ when color == Colors.yellow || color.value == Colors.yellow.toARGB32() => _getShortLabel('Favorite', 'Favorit', '收藏', 'お気に入り', language),
      _ when color == Colors.orange || color.value == Colors.orange.toARGB32() => _getShortLabel('Inspiring', 'Inspiratif', '鼓舞', 'インスピレーション', language),
      _ when color == Colors.pink || color.value == Colors.pink.toARGB32() => _getShortLabel('Love', 'Cinta', '爱', '愛', language),
      _ when color == Colors.red || color.value == Colors.red.toARGB32() => _getShortLabel('Important', 'Penting', '重要', '重要', language),
      _ when color == Colors.purple || color.value == Colors.purple.toARGB32() => _getShortLabel('Study', 'Belajar', '学习', '学習', language),
      _ when color == Colors.blue || color.value == Colors.blue.toARGB32() => _getShortLabel('Wisdom', 'Hikmah', '智慧', '知恵', language),
      _ when color == Colors.cyan || color.value == Colors.cyan.toARGB32() => _getShortLabel('Peace', 'Damai', '和平', '平和', language),
      _ when color == Colors.green || color.value == Colors.green.toARGB32() => _getShortLabel('Hope', 'Harapan', '希望', '希望', language),
      _ when color == Colors.teal || color.value == Colors.teal.toARGB32() => _getShortLabel('Nature', 'Alam', '自然', '自然', language),
      _ => _getShortLabel('Other', 'Lainnya', '其他', 'その他', language),
    };
  }

  String _getShortLabel(String en, String id, String zh, String ja, String language) {
    return switch (language) {
      'id' => id,
      'en' => en,
      'zh' => zh,
      'ja' => ja,
      _ => en,
    };
  }
}

