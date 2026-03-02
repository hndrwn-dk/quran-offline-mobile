import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/features/home/home_screen.dart';

/// Configurable app logo path for language screen. Fallback to icon if load fails.
const String _logoAssetPath = 'assets/icon/splash_icon.png';

const String _prefKeyLanguageDone = 'language_selection_done';

Future<bool> _hasCompletedLanguageSelection() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_prefKeyLanguageDone) ?? false;
}

/// For users upgrading: if they already had app language set, mark selection done so they don't see the picker.
Future<void> _migrateLegacyIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(_prefKeyLanguageDone);
  if (done == true) return;
  final hasAppLanguage = prefs.getString('appLanguage') != null;
  if (hasAppLanguage) await prefs.setBool(_prefKeyLanguageDone, true);
}

Future<void> _markLanguageSelectionDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKeyLanguageDone, true);
}

Future<void> _onLanguageSelected(
  BuildContext context,
  WidgetRef ref,
  String lang,
) async {
  final notifier = ref.read(settingsProvider.notifier);
  await notifier.updateAppLanguage(lang);
  await notifier.updateLanguage(lang);
  await _markLanguageSelectionDone();
  if (context.mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

/// Shown on first launch. User picks one language; it sets both app UI and translation language.
class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  static Future<bool> hasCompletedSelection() => _hasCompletedLanguageSelection();

  /// Call before hasCompletedSelection so upgraders with existing appLanguage skip the picker.
  static Future<void> migrateLegacyIfNeeded() => _migrateLegacyIfNeeded();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Keep exact multilingual header text
    const multilingualHeader =
        'Pilih bahasa • Choose language • 选择语言 • 言語を選択';

    final options = [
      _Option(lang: 'id', label: 'Bahasa Indonesia', code: 'ID'),
      _Option(lang: 'en', label: 'English', code: 'EN'),
      _Option(lang: 'zh', label: '中文', code: 'ZH'),
      _Option(lang: 'ja', label: '日本語', code: 'JA'),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo (56–72dp, centered, with fallback)
                    _buildLogo(context, colorScheme),
                    const SizedBox(height: 20),
                    // Multilingual header (bigger than subtitle, muted)
                    Text(
                      multilingualHeader,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // Subtitle (smaller than multilingual header)
                    Text(
                      'You can change this later in Settings.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // iOS-clean list tiles
                    ...options.map((opt) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LanguageTile(
                            option: opt,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onTap: () =>
                                _onLanguageSelected(context, ref, opt.lang),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, ColorScheme colorScheme) {
    const size = 88.0;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _logoAssetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 44,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final _Option option;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.option,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.8);

    return Material(
      color: colorScheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        option.label,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (option.code.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          option.code,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Option {
  final String lang;
  final String label;
  final String code;
  const _Option({
    required this.lang,
    required this.label,
    required this.code,
  });
}
